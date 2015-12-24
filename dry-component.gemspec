# coding: utf-8
require File.expand_path('../lib/dry/component/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'dry-component'
  spec.version       = Dry::Component::VERSION
  spec.authors       = ['Piotr Solnica']
  spec.email         = ['piotr.solnica@gmail.com']
  spec.summary       = 'Organize your code into reusable components'
  spec.homepage      = 'https://github.com/dryrb/dry-component'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'memoizable', '~> 0.4'
  spec.add_runtime_dependency 'inflecto', '>= 0.0.2'
  spec.add_runtime_dependency 'dry-container', '~> 0.2', '>= 0.2.7'
  spec.add_runtime_dependency 'dry-auto_inject', '~> 0.1'
  spec.add_runtime_dependency 'dry-configurable', '~> 0.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
