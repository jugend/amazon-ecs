# amazon-ecs

`amazon-ecs` is a generic Ruby wrapper to access Amazon Product Advertising API.

You can easily extend the library to support any of the operations supported by the API. 

The library wraps around Nokogiri element object. It provides an easy access to the XML response 
structure through an XML path instead of an object attribute. The idea is the API evolves,
there will be changes to the XML schema. With `amazon-ecs`, your code will still work, only
the XML path needs to be updated.

## Installation

```shell
gem install amazon-ecs
```

## How to use it

```ruby
require 'amazon/ecs'

# Configure your access key, secret key and other options such as the associate tag.
# Options set in the configure block will be merged with the pre-configured default 
# options, i.e.
#  options[:version] => "2011-08-01"
#  options[:service] => "AWSECommerceService"
Amazon::Ecs.configure do |options|
  options[:AWS_access_key_id] = '[your access key]'
  options[:AWS_secret_key] = '[you secret key]'
  options[:associate_tag] = '[your associate tag]'
end

# Or if you need to replace the default options, overwrite the options value, e.g.
# Amazon::Ecs.options = {
#  :version => "2013-08-01",
#  :service => "AWSECommerceService"
#  :associate_tag => '[your associate tag]',
#  :AWS_access_key_id => '[your developer token]',
#  :AWS_secret_key => '[your secret access key]'
# }

# options provided on method call will be merged with the default options
res = Amazon::Ecs.item_search('ruby', {:response_group => 'Medium', :sort => 'salesrank'})

# search amazon uk
res = Amazon::Ecs.item_search('ruby', :country => 'uk')

# search all items, default search index is Books
res = Amazon::Ecs.item_search('ruby', :search_index => 'All')

# some common response object methods
res.is_valid_request?     # return true if request is valid
res.has_error?            # return true if there is an error
res.error                 # return error message if there is any
res.total_pages           # return total pages
res.total_results         # return total results
res.item_page             # return current page no if :item_page option is provided

# traverse through each item (Amazon::Element)
res.items.each do |item|
  # retrieve string value using XML path
  item.get('ASIN')
  item.get('ItemAttributes/Title')

  # return Amazon::Element instance
  item_attributes = item.get_element('ItemAttributes')
  item_attributes.get('Title')

  # return first author or a string array of authors
  item_attributes.get('Author')          # 'Author 1'
  item_attributes.get_array('Author')    # ['Author 1', 'Author 2', ...]

  # return an hash of children text values with the element names as the keys
  item.get_hash('SmallImage') # {:url => ..., :width => ..., :height => ...}

  # return the first matching path as Amazon::Element
  item_height = item.get_element('ItemDimensions/Height')
  
  # retrieve attributes from Amazon::Element
  item_height.attributes['Units']   # 'hundredths-inches'
  
  # return an array of Amazon::Element
  authors = item.get_elements('Author')

  # return Nokogiri::XML::NodeSet object or nil if not found
  reviews = item/'EditorialReview'

  # traverse through Nokogiri elements
  reviews.each do |review|
    # Getting hash value out of Nokogiri element
    Amazon::Element.get_hash(review) # [:source => ..., :content ==> ...]

    # Or to get unescaped HTML values
    Amazon::Element.get_unescaped(review, 'Source')
    Amazon::Element.get_unescaped(review, 'Content')
    
    # Or this way
    el = Amazon::Element.new(review)
    el.get_unescaped('Source')
    el.get_unescaped('Content')
  end
end

# Extend Amazon::Ecs, replace 'other_operation' with the appropriate name
module Amazon
  class Ecs
    def self.other_operation(item_id, opts={})
      opts[:operation] = '[other valid operation supported by Product Advertising API]'
      
      # setting default option value
      opts[:item_id] = item_id
    
      self.send_request(opts)
    end
  end
end

Amazon::Ecs.other_operation('[item_id]', :param1 => 'abc', :param2 => 'xyz')
```

Refer to Amazon Product Advertising API documentation for more information:
https://affiliate-program.amazon.com/gp/advertising/api/detail/main.html

## Source Codes

* http://github.com/jugend/amazon-ecs

## Credits

Thanks to Dan Milne and Bryan Housel for the pull requests.

## License

[The MIT License]
