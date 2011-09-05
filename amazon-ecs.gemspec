# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |gem|
  gem.name = %q{amazon-ecs}
  gem.version = "2.1.1"
  gem.date = "2011-09-05"
  gem.authors = ["Herryanto Siatono"]
  gem.description = %q{Generic Amazon Product Advertising Ruby API}
  gem.email = %q{herryanto@gmail.com}
  gem.extra_rdoc_files = ["README"]
  gem.files = [ "README", "lib/amazon/ecs.rb", "test/amazon/ecs_test.rb" ]
  gem.has_rdoc = true
  gem.homepage = %q{https://github.com/jugend/amazon-ecs}
  gem.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  gem.require_paths = ["lib"]
  gem.rubygems_version = %q{1.3.1}
  gem.summary = %q{Generic Amazon Product Advertising Ruby API}
 
  if gem.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    gem.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      gem.add_runtime_dependency("nokogiri", ">= 1.4.0")
      gem.add_runtime_dependency("ruby-hmac", ">= 0.3.2")
    else
      gem.add_dependency("nokogiri", ">= 1.4.0")
      gem.add_dependency("ruby-hmac", ">= 0.3.2")
    end
  else
    gem.add_dependency("nokogiri", ">= 1.4.0")
    gem.add_dependency("ruby-hmac", ">= 0.3.2")
  end
end