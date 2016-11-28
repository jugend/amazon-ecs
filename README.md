# amazon-ecs

`amazon-ecs` is a generic Ruby wrapper to access Amazon Product Advertising API.

The library wraps around [Nokogiri](http://www.nokogiri.org/) element object. It provides an easy access to the XML response elements and attributes.

The gist is, if the API and the response schema are updated, `amazon-ecs` library will still work,
and you only need to update the xml paths.

## Installation

```shell
gem install amazon-ecs
```

## Usage

```ruby
require 'amazon/ecs'

# default options:
#  options[:version] => "2013-08-01"
#  options[:service] => "AWSECommerceService"
Amazon::Ecs.configure do |options|
  options[:AWS_access_key_id] = '[your access key]'
  options[:AWS_secret_key] = '[you secret key]'
  options[:associate_tag] = '[your associate tag]'
end

# If you intend to query more than one local you need to sign up 
# and have an associate tag for each to receive credit.

# To set up differrent Associate IDs for each local:
# pass a hash to the options [:associate_tag] for each country local you intend to query
Amazon::Ecs.configure do |options|
  options[:AWS_access_key_id] = '[your access key]'
  options[:AWS_secret_key] = '[you secret key]'
  options[:associate_tag] = {
      :us => '[your associate tag]',
      :uk => '[your associate tag]',
      :ca => '[your associate tag]',
      :de => '[your associate tag]',
      :jp => '[your associate tag]',
      :fr => '[your associate tag]',
      :it => '[your associate tag]',
      :cn => '[your associate tag]',
      :es => '[your associate tag]',
      :in => '[your associate tag]',
      :br => '[your associate tag]',
      :mx => '[your associate tag]'
    }
end


# to overwrite the whole options
# Amazon::Ecs.options = { ... }

# options will be merged with the default options
res = Amazon::Ecs.item_search('ruby', {:response_group => 'Medium', :sort => 'salesrank'})

# search amazon uk
res = Amazon::Ecs.item_search('ruby', :country => 'uk')

# search all items, default search index: Books
res = Amazon::Ecs.item_search('ruby', :search_index => 'All')

res.is_valid_request?
res.has_error?
res.error                                 # error message
res.total_pages
res.total_results
res.item_page                             # current page no if :item_page option is provided

# find elements matching 'Item' in response object
res.items.each do |item|
  # retrieve string value using XML path
  item.get('ASIN')
  item.get('ItemAttributes/Title')

  # return Amazon::Element instance
  item_attributes = item.get_element('ItemAttributes')
  item_attributes.get('Title')

  item_attributes.get_unescaped('Title') # unescape HTML entities
  item_attributes.get_array('Author')    # ['Author 1', 'Author 2', ...]
  item_attributes.get('Author')          # 'Author 1'

  # return a hash object with the element names as the keys
  item.get_hash('SmallImage') # {:url => ..., :width => ..., :height => ...}

  # return the first matching path
  item_height = item.get_element('ItemDimensions/Height')
  item_height.attributes['Units']        # 'hundredths-inches'

  # there are two ways to find elements:
  # 1) return an array of Amazon::Element
  reviews = item.get_elements('EditorialReview')
  reviews.each do |review|
    el.get('Content')
  end

  # 2) return Nokogiri::XML::NodeSet object or nil if not found
  reviews = item/'EditorialReview'
  reviews.each do |review|
    el = Amazon::Element.new(review)
    el.get('Content')
  end
end
```

## Other Operations

```ruby
# Item lookup
res = Amazon::Ecs.item_lookup("0974514055")
item = res.get_element("Item")

# Browse node lookup
res = Amazon::Ecs.browse_node_lookup("17")
nodes = res.get_elements("BrowseNode")
nodes.each do |node|
  node.get('Name')
end

# Similarity lookup
Amazon::ECS.similarity_lookup("0974514055")

# Other operation
Amazon::Ecs.send_request(:operation => '[OperationName]', :id => 123)
```

Refer to [Amazon Product Advertising API](https://affiliate-program.amazon.com/gp/advertising/api/detail/main.html)
documentation for more information on the operations and request parameters supported.

## Dump and Load

```ruby
res.marshal_dump         # xml string
res.marshal_load(xml)
```

## Debug

Turn on the debug mode to display API request params, full URL and XML response:

```ruby
Amazon::Ecs::debug = true
```
Or you could also set the `DEBUG_AMAZON_ECS` environment variable to 1.

```sh
DEBUG_AMAZON_ECS=1 [command]
```

## License

[The MIT License]
