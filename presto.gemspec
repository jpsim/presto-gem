# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "presto/version"

Gem::Specification.new do |s|
  s.name        = "presto"
  s.version     = Presto::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['JP Simard']
  s.email       = ["jp@jpsim.com"]
  s.homepage    = "https://github.com/jpsim/presto-gem"
  s.summary     = "Gem for interacting with Presto cards."
  s.description = "Gem for interacting with Presto cards."

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  
  s.add_dependency "mechanize", "2.7.3"

  s.add_development_dependency "rake"
end
