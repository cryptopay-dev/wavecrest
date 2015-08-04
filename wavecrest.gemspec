# coding: utf-8
require File.expand_path('../lib/wavecrest/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "wavecrest"
  spec.version       = Wavecrest::VERSION
  spec.authors       = ["Vadim Marchenko"]
  spec.email         = ["just.zimer@gmail.com"]
  spec.description   = 'Gem for wavecrest API'
  spec.summary       = ''
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'rest-client'
  spec.add_runtime_dependency 'json'
end
