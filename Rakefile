require "bundler/gem_tasks"
require "rake/testtask"



Rake::TestTask.new(:spec) do |t|
  t.libs << "spec"
  t.libs << "lib"
  t.test_files = FileList['spec/**/*_spec.rb']
  unless defined? Warning
    t.warning = false
  end
end

task :test => :spec
task :default => :spec

