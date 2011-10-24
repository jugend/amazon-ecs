require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/packagetask'

desc "Create the RDOC html files"
rd = Rake::RDocTask.new("rdoc") { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "amazon-ecs"
  rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'Readme.rdoc'
  rdoc.rdoc_files.include('Readme.rdoc', 'CHANGELOG')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('test/**/*.rb')
}

desc "Run the unit tests in test"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task :default => :test