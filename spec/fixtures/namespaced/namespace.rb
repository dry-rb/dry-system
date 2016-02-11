module Tests
  module Namespaced
    extend Dry::Component::Namespace

    configure do |config|
      config.root = Pathname(__dir__)
      config.auto_register = 'foos'
    end

    require 'something'
  end
end
