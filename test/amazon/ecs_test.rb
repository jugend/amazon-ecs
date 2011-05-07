# coding: utf-8

require 'rubygems'
require 'test/unit'

require './' + File.dirname(__FILE__) + '/../../lib/amazon/ecs'

class Amazon::EcsTest < Test::Unit::TestCase

  AWS_ACCESS_KEY_ID = '0XQXXC6YV2C85DX1BF02'
  AWS_SECRET_KEY = 'fwLOn0Y/IUXEM8Hk49o7QJV+ryOscbhXRb6CmA5l'
  
  raise "Please specify set your AWS_ACCESS_KEY_ID" if AWS_ACCESS_KEY_ID.empty?
  raise "Please specify set your AWS_SECRET_KEY" if AWS_SECRET_KEY.empty?
  
  Amazon::Ecs.configure do |options|
    options[:response_group] = 'Large'
    options[:aWS_access_key_id] = AWS_ACCESS_KEY_ID
    options[:aWS_secret_key] = AWS_SECRET_KEY
  end

  ## Test item_search
  def test_item_search
    resp = Amazon::Ecs.item_search('ruby')
    
    assert(resp.is_valid_request?)
    assert(resp.total_results >= 3600)
    assert(resp.total_pages >= 360)
    
    signature_elements = (resp.doc/"arguments/argument").select do |ele| 
      ele.attributes['name'] == 'Signature' || ele.attributes['Name'] == 'Signature'
    end.length
    
    assert(signature_elements == 1)
  end
      
  def test_item_search_with_special_characters
    Amazon::Ecs.debug = true
    resp = Amazon::Ecs.item_search('()*&^%$')
    assert(resp.is_valid_request?)
  end
   
  def test_item_search_with_paging
    resp = Amazon::Ecs.item_search('ruby', :item_page => 2)
    assert resp.is_valid_request?
    assert 2, resp.item_page
  end
   
  def test_item_search_with_invalid_request
    resp = Amazon::Ecs.item_search(nil)
    assert !resp.is_valid_request?
  end
   
  def test_item_search_with_no_result
    resp = Amazon::Ecs.item_search('afdsafds')
    
    assert resp.is_valid_request?
    assert_equal "We did not find any matches for your request.", 
      resp.error
  end
  
  def test_item_search_uk
    resp = Amazon::Ecs.item_search('ruby', :country => :uk)
    assert resp.is_valid_request?
  end
  
  def test_item_search_by_author
    resp = Amazon::Ecs.item_search('dave', :type => :author)
    assert resp.is_valid_request?
  end
  
  def test_item_get
    resp = Amazon::Ecs.item_search("0974514055")
    item = resp.first_item
        
    # test get
    assert_equal "Programming Ruby: The Pragmatic Programmers' Guide, Second Edition", 
      item.get("itemattributes/title")
      
    # test get_array
    assert_equal ['Dave Thomas', 'Chad Fowler', 'Andy Hunt'], 
      item.get_array("author")
   
    # test get_hash
    small_image = item.get_hash("smallimage")
    
    assert_equal 3, small_image.keys.size
    assert_match ".jpg", small_image[:url]
    assert_equal "75", small_image[:height]
    assert_equal "59", small_image[:width]
    
    # test /
    reviews = item/"editorialreview"
    reviews.each do |review|
      # returns unescaped HTML content, Hpricot escapes all text values
      assert Amazon::Element.get_unescaped(review, 'source')
      assert Amazon::Element.get_unescaped(review, 'content')
    end
  end
  
  ## Test item_lookup
  def test_item_lookup
    resp = Amazon::Ecs.item_lookup('0974514055')
    assert_equal "Programming Ruby: The Pragmatic Programmers' Guide, Second Edition", 
    resp.first_item.get("itemattributes/title")
  end
  
  def test_item_lookup_with_invalid_request
    resp = Amazon::Ecs.item_lookup(nil)
    assert resp.has_error?
    assert resp.error
  end
   
  def test_item_lookup_with_no_result
    resp = Amazon::Ecs.item_lookup('abc')
    
    assert resp.is_valid_request?
    assert_match(/ABC is not a valid value for ItemId/, resp.error)
  end  
  
  def test_search_and_convert
    resp = Amazon::Ecs.item_lookup('0974514055')
    title = resp.first_item.get("itemattributes/title")
    authors = resp.first_item.search_and_convert("author")
    
    assert_equal "Programming Ruby: The Pragmatic Programmers' Guide, Second Edition", title
    assert authors.is_a?(Array)
    assert 3, authors.size
    assert_equal "Dave Thomas", authors.first.get
  end
  
  def test_get_elements
    resp = Amazon::Ecs.item_lookup('0974514055')
    item = resp.first_item
    
    authors = item.get_elements("author")
    assert authors.is_a?(Array)
    assert 3, authors.size
    assert authors.first.is_a?(Amazon::Element)
    assert_equal "Dave Thomas", authors.first.get
    
    asin = item.get_elements("asin")
    assert asin.is_a?(Array)
    assert 1, authors.size
  end
  
  def test_get_element_and_attributes
    resp = Amazon::Ecs.item_lookup('0974514055')
    item = resp.first_item

    first_author = item.get_element("author")
    assert_equal "Dave Thomas", first_author.get
    assert_equal nil, first_author.attributes['unknown']
    
    item_height = item.get_element("itemdimensions/height")
    assert_equal "hundredths-inches", item_height.attributes['units']
  end
  
  def test_multibyte_search
    resp = Amazon::Ecs.item_search("パソコン")
    assert(resp.is_valid_request?)
  end

  def test_marshal_dump_request
    resp = Amazon::Ecs::Response.new(File.read(File.expand_path('../../fixtures/item_search.xml', __FILE__)))
    dumped_resp = Marshal.load(Marshal.dump(resp))
    assert_equal resp.doc.to_s,       dumped_resp.doc.to_s
    assert_equal resp.items.size,     dumped_resp.items.size
    assert_equal resp.item_page,      dumped_resp.item_page
    assert_equal resp.total_results,  dumped_resp.total_results
    assert_equal resp.total_pages,    dumped_resp.total_pages
  end
end
