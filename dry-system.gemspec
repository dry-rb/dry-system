require File.expand_path('../lib/dry/system/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'dry-system'
  spec.version       = Dry::System::VERSION
  spec.authors       = ['Piotr Solnica']
  spec.email         = ['piotr.solnica@gmail.com']
  spec.summary       = 'Organize your code into reusable components'
  spec.homepage      = 'http://dry-rb.org/gems/dry-system'
  spec.license       = 'MIT'

  spec.files         = Dir['CHANGELOG.md', 'LICENSE', 'README.md', 'lib/**/*']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.0'
  spec.add_runtime_dependency 'dry-core', '>= 0.3.1'
  spec.add_runtime_dependency 'dry-auto_inject', '>= 0.4.0'
  spec.add_runtime_dependency 'dry-configurable', '~> 0.7', '>= 0.7.0'
  spec.add_runtime_dependency 'dry-container', '~> 0.7'
  spec.add_runtime_dependency 'dry-equalizer', '~> 0.2'
  spec.add_runtime_dependency 'dry-inflector', '~> 0.1', '>= 0.1.2'
  spec.add_runtime_dependency 'dry-struct', '~> 0.5'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
