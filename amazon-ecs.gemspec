# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'amazon/ecs'

Gem::Specification.new do |gem|
  gem.name = %q{amazon-ecs}
  gem.version = Amazon::Ecs::VERSION
  gem.platform = Gem::Platform::RUBY
  gem.authors = ["Herryanto Siatono"]
  gem.email = %q{herryanto@gmail.com}
  gem.homepage = %q{https://github.com/jugend/amazon-ecs}
  gem.summary = %q{Generic Amazon Product Advertising Ruby API.}
  gem.description = %q{Generic Amazon Product Advertising Ruby API.}

  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- test/*`.split("\n")
  gem.require_paths = ["lib"]
 
  if gem.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    gem.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      gem.add_runtime_dependency("nokogiri", "~> 1.6")
      gem.add_runtime_dependency("ruby-hmac", "~> 0.4")
    else
      gem.add_dependency("nokogiri", "~> 1.6")
      gem.add_dependency("ruby-hmac", "~> 0.4")
    end
  else
    gem.add_dependency("nokogiri", "~> 1.6")
    gem.add_dependency("ruby-hmac", "~> 0.4")
  end
end
