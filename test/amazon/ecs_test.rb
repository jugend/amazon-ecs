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
    assert resp.is_valid_request?,
      "Not a valid request"
    assert (resp.total_results >= 3600),
      "Results returned (#{resp.total_results}) were < 3600"
    assert (resp.total_pages >= 360),
      "Pages returned (#{resp.total_pages}) were < 360"
  end


  def test_item_search_with_special_characters
    Amazon::Ecs.debug = true
    resp = Amazon::Ecs.item_search('()*&^%$')
    assert resp.is_valid_request?,
      "Not a valid request"
  end


  def test_item_search_with_paging
    resp = Amazon::Ecs.item_search('ruby', :item_page => 2)
    assert resp.is_valid_request?, 
      "Not a valid request"
    assert_equal 2, resp.item_page,
      "Page returned (#{resp.item_page}) different from expected (2)"
  end


  def test_item_search_with_invalid_request
    resp = Amazon::Ecs.item_search(nil)
    assert !resp.is_valid_request?, 
      "Expected invalid request error"
  end


  def test_item_search_with_no_result
    resp = Amazon::Ecs.item_search('afdsafds')    
    assert resp.is_valid_request?, 
      "Not a valid request"
    assert_equal "We did not find any matches for your request.", resp.error, 
      "Error string different from expected"
  end


  def test_item_search_uk
    resp = Amazon::Ecs.item_search('ruby', :country => :uk)
    assert resp.is_valid_request?, 
      "Not a valid request"
  end


  def test_item_search_by_author
    resp = Amazon::Ecs.item_search('dave', :type => :author)
    assert resp.is_valid_request?, 
      "Not a valid request"
  end


  def test_item_get
    resp = Amazon::Ecs.item_search("0974514055")
    item = resp.first_item
        
    # test get
    assert_equal "Programming Ruby: The Pragmatic Programmers' Guide, Second Edition", 
      item.get("itemattributes/title"), 
      "Title different from expected"
      
    # test get_array
    assert_equal ['Dave Thomas', 'Chad Fowler', 'Andy Hunt'], 
      item.get_array("author"), 
      "Authors Array different from expected"

    # test get_hash
    small_image = item.get_hash("smallimage")
    assert_equal 3, small_image.keys.size,
      "Image hash key count (#{small_image.keys.size}) different from expected (3)"
    assert_match ".jpg", small_image[:url],
      "Image type different from expected (.jpg)"
    assert_equal "75", small_image[:height],
      "Image height (#{small_image[:height]}) different from expected (75)"
    assert_equal "59", small_image[:width],
      "Image width (#{small_image[:width]}) different from expected (59)"

    # test /
    reviews = item/"editorialreview"
    reviews.each do |review|
      # returns unescaped HTML content, Nokogiri escapes all text values
      assert Amazon::Element.get_unescaped(review, 'source'),
        "XPath editorialreview failed to get source"
      assert Amazon::Element.get_unescaped(review, 'content'),
        "XPath editorialreview failed to get content"
    end
  end


  ## Test item_lookup
  def test_item_lookup
    resp = Amazon::Ecs.item_lookup('0974514055')
    assert_equal "Programming Ruby: The Pragmatic Programmers' Guide, Second Edition", 
      resp.first_item.get("itemattributes/title"),
      "Title different from expected"
  end


  def test_item_lookup_with_invalid_request
    resp = Amazon::Ecs.item_lookup(nil)
    assert resp.has_error?,
      "Response should have been invalid"
    assert resp.error,
      "Response should have contained an error"
  end


  def test_item_lookup_with_no_result
    resp = Amazon::Ecs.item_lookup('abc')    
    assert resp.is_valid_request?,
      "Not a valid request"
    assert_match /ABC is not a valid value for ItemId/, resp.error, 
      "Error Message for lookup of ASIN = ABC different from expected"
  end


  # Deprecated
  def test_search_and_convert
    resp = Amazon::Ecs.item_lookup('0974514055')
    title = resp.first_item.get("itemattributes/title")
    authors = resp.first_item.search_and_convert("author")
  
    assert_equal "Programming Ruby: The Pragmatic Programmers' Guide, Second Edition", title,
      "Title different from expected"
    assert_instance_of Array, authors,
      "Authors should be an Array"
    assert_equal 3, authors.size,
      "Author array size (#{authors.size}) different from expected (3)"
    assert_equal "Dave Thomas", authors.first.get,
      "First Author (#{authors.first.get}) different from expected (Dave Thomas)"
  end


  def test_get_elements
    resp = Amazon::Ecs.item_lookup('0974514055')
    item = resp.first_item

    authors = item.get_elements("author")
    assert_instance_of Array, authors,
      "Authors should be an Array"
    assert_equal 3, authors.size,
      "Author array size (#{authors.size}) different from expected (3)"
    assert_instance_of Amazon::Element, authors.first,
      "Authors array first element (#{authors.first.class}) should be an Amazon::Element"
    assert_equal "Dave Thomas", authors.first.get,
      "First Author (#{authors.first.get}) different from expected (Dave Thomas)"
    
    asin = item.get_elements("./asin")
    assert_instance_of Array, asin,
      "ASIN should be an Array"
    assert_equal 1, asin.size,
      "ASIN array size (#{asin.size}) different from expected (1)"
  end


  def test_get_element_and_attributes
    resp = Amazon::Ecs.item_lookup('0974514055')
    item = resp.first_item

    first_author = item.get_element("author")
    assert_equal "Dave Thomas", first_author.get,
      "First Author (#{first_author.get}) different from expected (Dave Thomas)"
    assert_nil first_author.attributes['unknown'],
      "First Author 'unknown' attributes should be nil"
    
    item_height = item.get_element("itemdimensions/height")
    units = item_height.attributes['units'].inner_html if item_height
    assert_equal "hundredths-inches", units,
      "Item Height 'units' attributes (#{units}) different from expected (hundredths-inches)"
  end


  def test_multibyte_search
    resp = Amazon::Ecs.item_search("パソコン")
    assert resp.is_valid_request?,
      "Not a valid request"
  end
  
end
