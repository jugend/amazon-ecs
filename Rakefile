require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/packagetask'

spec = Gem::Specification.new do |s| 
  s.name = "amazon-ecs"
  s.version = "0.5.4"
  s.author = "Herryanto Siatono"
  s.email = "herryanto@pluitsolutions.com"
  s.homepage = "http://amazon-ecs.rubyforge.net/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Generic Amazon E-commerce Service (ECS) REST API. Supports ECS 4.0."
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.autorequire = "name"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "CHANGELOG"]
  s.add_dependency("hpricot", ">= 0.4")
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end

desc "Create the RDOC html files"
rd = Rake::RDocTask.new("rdoc") { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "amazon-ecs"
  rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'README'
  rdoc.rdoc_files.include('README', 'CHANGELOG')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('test/**/*.rb')
}

desc "Run the unit tests in test" 
Rake::TestTask.new(:test) do |t|
  t.libs << "test" 
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end