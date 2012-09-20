# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pbxproject/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikko Kokkonen"]
  gem.email         = ["mikko@owlforestry.com"]
  gem.description   = %q{Pure ruby -interface to XCode 4 project files. Read and modify pbxproject
    files with ease.}
  gem.summary       = %q{Manage XCode 4 project files with pure-ruby library.}
  gem.homepage      = "http://github.com/owlforestry/pbxproject"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pbxproject"
  gem.require_paths = ["lib"]
  gem.version       = PBXProject::VERSION
  
  gem.add_dependency 'thor'
  gem.add_development_dependency 'version'
end
