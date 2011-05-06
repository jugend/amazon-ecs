#--
# Copyright (c) 2009 Herryanto Siatono, Pluit Solutions
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'net/http'
require 'nokogiri'
require 'cgi'
require 'hmac-sha2'
require 'base64'
require 'openssl'

module Amazon
  class RequestError < StandardError; end
  
  class Ecs
    SERVICE_URLS = {:us => 'http://webservices.amazon.com/onca/xml?',
        :uk => 'http://webservices.amazon.co.uk/onca/xml?',
        :ca => 'http://webservices.amazon.ca/onca/xml?',
        :de => 'http://webservices.amazon.de/onca/xml?',
        :jp => 'http://webservices.amazon.co.jp/onca/xml?',
        :fr => 'http://webservices.amazon.fr/onca/xml?',
        :it => 'http://webservices.amazon.it/onca/xml?'
    }
    
    OPENSSL_DIGEST_SUPPORT = OpenSSL::Digest.constants.include?( 'SHA256' ) ||
                             OpenSSL::Digest.constants.include?( :SHA256 )
    
    OPENSSL_DIGEST = OpenSSL::Digest::Digest.new( 'sha256' ) if OPENSSL_DIGEST_SUPPORT
    
    @@options = {
      :version => "2010-10-01",
      :service => "AWSECommerceService"
    }
    
    @@debug = false

    # Default search options
    def self.options
      @@options
    end
    
    # Set default search options
    def self.options=(opts)
      @@options = opts
    end
    
    # Get debug flag.
    def self.debug
      @@debug
    end
    
    # Set debug flag to true or false.
    def self.debug=(dbg)
      @@debug = dbg
    end
    
    def self.configure(&proc)
      raise ArgumentError, "Block is required." unless block_given?
      yield @@options
    end
    
    # Search amazon items with search terms. Default search index option is 'Books'.
    # For other search type other than keywords, please specify :type => [search type param name].
    def self.item_search(terms, opts = {})
      opts[:operation] = 'ItemSearch'
      opts[:search_index] = opts[:search_index] || 'Books'
      
      type = opts.delete(:type)
      if type 
        opts[type.to_sym] = terms
      else 
        opts[:keywords] = terms
      end
      
      self.send_request(opts)
    end

    # Search an item by ASIN no.
    def self.item_lookup(item_id, opts = {})
      opts[:operation] = 'ItemLookup'
      opts[:item_id] = item_id
      
      self.send_request(opts)
    end    
          
    # Generic send request to ECS REST service. You have to specify the :operation parameter.
    def self.send_request(opts)
      opts = self.options.merge(opts) if self.options
      
      # Include other required options
      opts[:timestamp] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

      request_url = prepare_url(opts)
      log "Request URL: #{request_url}"
      
      res = Net::HTTP.get_response(URI::parse(request_url))
      unless res.kind_of? Net::HTTPSuccess
        raise Amazon::RequestError, "HTTP Response: #{res.code} #{res.message}"
      end
      Response.new(res.body)
    end

    # Response object returned after a REST call to Amazon service.
    class Response
      # XML input is in string format
      def initialize(xml)
        @doc = Nokogiri::XML(xml)
        @doc.remove_namespaces!
        @doc.xpath("//*").each { |elem| elem.name = elem.name.downcase }
        @doc.xpath("//@*").each { |att| att.name = att.name.downcase }
      end

      # Return Nokogiri::XML::Document object.
      def doc
        @doc
      end

      # Return true if request is valid.
      def is_valid_request?
        Element.get(@doc, "//isvalid") == "True"
      end

      # Return true if response has an error.
      def has_error?
        !(error.nil? || error.empty?)
      end

      # Return error message.
      def error
        Element.get(@doc, "//error/message")
      end
      
      # Return error code
      def error_code
        Element.get(@doc, "//error/code")
      end
      
      # Return an array of Amazon::Element item objects.
      def items
        @items ||= (@doc/"item").collect { |item| Element.new(item) }
      end
      
      # Return the first item (Amazon::Element)
      def first_item
        items.first
      end
      
      # Return current page no if :item_page option is when initiating the request.
      def item_page
        @item_page ||= Element.get(@doc, "//itempage").to_i
      end

      # Return total results.
      def total_results
        @total_results ||= Element.get(@doc, "//totalresults").to_i
      end
      
      # Return total pages.
      def total_pages
        @total_pages ||= Element.get(@doc, "//totalpages").to_i
      end
    end
    
    protected
      def self.log(s)
        return unless self.debug
        if defined? RAILS_DEFAULT_LOGGER
          RAILS_DEFAULT_LOGGER.error(s)
        elsif defined? LOGGER
          LOGGER.error(s)
        else
          puts s
        end
      end
      
    private 
      def self.prepare_url(opts)
        country = opts.delete(:country)
        country = (country.nil?) ? 'us' : country
        request_url = SERVICE_URLS[country.to_sym]
        raise Amazon::RequestError, "Invalid country '#{country}'" unless request_url

        secret_key = opts.delete(:aWS_secret_key)
        request_host = URI.parse(request_url).host
        
        qs = ''
        
        opts = opts.collect do |a,b| 
          [camelize(a.to_s), b.to_s] 
        end
        
        opts = opts.sort do |c,d| 
          c[0].to_s <=> d[0].to_s
        end
        
        opts.each do |e| 
          log "Adding #{e[0]}=#{e[1]}"
          next unless e[1]
          e[1] = e[1].join(',') if e[1].is_a? Array
          # v = URI.encode(e[1].to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
          v = self.url_encode(e[1].to_s)
          qs << "&" unless qs.length == 0
          qs << "#{e[0]}=#{v}"
        end
        
        signature = ''
        unless secret_key.nil?
          request_to_sign="GET\n#{request_host}\n/onca/xml\n#{qs}"
          signature = "&Signature=#{sign_request(request_to_sign, secret_key)}"
        end

        "#{request_url}#{qs}#{signature}"
      end
      
      def self.url_encode(string)
        string.gsub( /([^a-zA-Z0-9_.~-]+)/ ) do
          '%' + $1.unpack( 'H2' * $1.bytesize ).join( '%' ).upcase
        end
      end
      
      def self.camelize(s)
        s.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      end
      
      def self.sign_request(url, key)
        return nil if key.nil?
        
        if (OPENSSL_DIGEST_SUPPORT)
          signature = OpenSSL::HMAC.digest(OPENSSL_DIGEST, key, url)
          signature = [signature].pack('m').chomp
        else
          signature = Base64.encode64( HMAC::SHA256.digest(key, url) ).strip
        end
        signature = URI.escape(signature, Regexp.new("[+=]"))
        return signature
      end
  end

  # Internal wrapper class to provide convenient method to access Nokogiri element value.
  class Element
    # Pass Nokogiri::XML::Element object
    def initialize(element)
      @element = element
    end

    # Returns Nokogiri::XML::Element object    
    def elem
      @element
    end
    
    # Returns a Nokogiri::XML::NodeSet of elements matching the given path. Example: element/"author".
    def /(path)
      elements = @element/path
      return nil if elements.size == 0
      elements
    end
    
    # Return an array of Amazon::Element matching the given path, or Amazon::Element if there 
    # is only one element found.
    #
    # <b>DEPRECATED:</b> Please use <tt>get_elements</tt> and <tt>get_element</tt> instead.
    def search_and_convert(path)
      elements = self.get_elements(path)
      return elements.first if elements and elements.size == 1
      elements
    end
    
    # Return an array of Amazon::Element matching the given path
    def get_elements(path)
      elements = self./(path)
      return unless elements
      elements = elements.map{|element| Element.new(element)}
    end
    
    # Similar with search_and_convert but always return first element if more than one elements found
    def get_element(path)
      elements = get_elements(path)
      elements[0] if elements
    end

    # Get the text value of the given path, leave empty to retrieve current element value.
    def get(path='.')
      Element.get(@element, path)
    end
    
    # Get the unescaped HTML text of the given path.
    def get_unescaped(path='.')
      Element.get_unescaped(@element, path)
    end
    
    # Get the array values of the given path.
    def get_array(path='.')
      Element.get_array(@element, path)
    end

    # Get the children element text values in hash format with the element names as the hash keys.
    def get_hash(path='.')
      Element.get_hash(@element, path)
    end
    
    def attributes
      return unless self.elem
      self.elem.attributes
    end
    
    # Similar to #get, except an element object must be passed-in.
    def self.get(element, path='.')
      return unless element
      result = element.at_xpath(path)
      result = result.inner_html if result
      result
    end
    
    # Similar to #get_unescaped, except an element object must be passed-in.    
    def self.get_unescaped(element, path='.')
      result = get(element, path)
      CGI::unescapeHTML(result) if result
    end

    # Similar to #get_array, except an element object must be passed-in.
    def self.get_array(element, path='.')
      return unless element
      
      result = element/path
      if (result.is_a? Nokogiri::XML::NodeSet) || (result.is_a? Array)
        result.collect { |item| Element.get(item) }
      else
        [Element.get(result)]
      end
    end

    # Similar to #get_hash, except an element object must be passed-in.
    def self.get_hash(element, path='.')
      return unless element
    
      result = element.at_xpath(path)
      if result
        hash = {}
        result = result.children
        result.each do |item|
          hash[item.name.to_sym] = item.inner_html
        end 
        hash
      end
    end
    
    def to_s
      elem.to_s if elem
    end
  end
end
