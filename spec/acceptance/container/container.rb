require 'dry/system'
require 'dry/system/container'

$LOAD_PATH.unshift(Pathname.new(__dir__).join('fixtures', 'bacon', 'lib').realpath.to_s)

Dry::System.register_system(Test::Bacon)

module Test
  class TestInflector < Dry::Inflector
    def constantize(input)
      Test.const_get(input)
    end
  end

  class AnotherContainer < Dry::System::Container
    Inject = injector

    configure do |config|
      config.root = Pathname.new(__dir__).join('fixtures/another_container')
      config.inflector = TestInflector.new
      config.name = :another
      config.default_namespace = :another
      config.auto_register = ['app']

      load_paths!('app', 'lib')
    end
  end

  class Container < Dry::System::Container
    Inject = injector

    setting :locale, :en_US

    configure do |config|
      config.root = Pathname.new(__dir__).join('fixtures/container')
      config.name = :test
      config.default_namespace = :test
      config.auto_register = ['app']

      load_paths!('app', 'lib')
    end

    import another: Test::AnotherContainer

    # Local providers, no dependencies

    # boot(:logger)                   # in system/boot/logger.rb
    #   -> nil
    # boot(:settings)                 # in system/boot/settings.rb
    #   -> nil

    # External providers, no dependencies

    # boot(:router, from: :bacon)     # in system/boot/router.rb
    #   -> nil
    # boot(:database, from: :bacon)   # in system/boot/database.rb
    #   -> nil

    # Local provider with dependencies

    # boot(:weather)                  # in system/boot/weather.rb
    #   -> :settings
    # boot(:notifications)            # in system/boot/notifications.rb
    #   -> bacon: :in_memory

    # Providers with unbooted dependencies. `#use` will auto-boot a registered
    # dependency from an external system before starting it.

    # boot(:local_service)            # in system/boot/local_service.rb
    #   use -> bacon: :dep

    boot(:service, from: :bacon)
    #   use -> bacon: :dep
  end
end
