# -*- encoding: utf-8 -*-
require "presto_api/version"

Gem::Specification.new do |s|
  s.name        = "presto_api"
  s.version     = Presto::VERSION
  s.licenses    = ['MIT']
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['JP Simard']
  s.email       = ["jp@jpsim.com"]
  s.homepage    = "https://github.com/jpsim/presto-gem"
  s.summary     = "Gem for interacting with Presto cards."
  s.description = "Gem for interacting with Presto cards, using mechanize."

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  
  s.add_dependency "mechanize", "2.7.3"

  s.add_development_dependency "rake", '~> 0'
end
