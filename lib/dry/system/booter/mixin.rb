module Dry
  module System
    module Booter
      module Mixin
        # Registers finalization function for a bootable component
        #
        # By convention, boot files for components should be placed in
        # `%{system_dir}/boot` and they will be loaded on demand when components
        # are loaded in isolation, or during finalization process.
        #
        # @example
        #   # system/container.rb
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.name = :core
        #       config.auto_register = %w(lib/apis lib/core)
        #     end
        #
        #   # system/boot/db.rb
        #   #
        #   # Simple component registration
        #   MyApp.boot(:db) do |container|
        #     require 'db'
        #
        #     container.register(:db, DB.new)
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration with lifecycle triggers
        #   MyApp.boot(:db) do |container|
        #     init do
        #       require 'db'
        #       DB.configure(ENV['DB_URL'])
        #       container.register(:db, DB.new)
        #     end
        #
        #     start do
        #       db.establish_connection
        #     end
        #
        #     stop do
        #       db.close_connection
        #     end
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration which uses another bootable component
        #   MyApp.boot(:db) do |container|
        #     use :logger
        #
        #     start do
        #       require 'db'
        #       DB.configure(ENV['DB_URL'], logger: logger)
        #       container.register(:db, DB.new)
        #     end
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration under a namespace. This will register the
        #   # db object under `persistence.db` key
        #   MyApp.namespace(:persistence) do |persistence|
        #     require 'db'
        #     DB.configure(ENV['DB_URL'], logger: logger)
        #     persistence.register(:db, DB.new)
        #   end
        #
        # @param name [Symbol] a unique identifier for a bootable component
        #
        # @see Lifecycle
        #
        # @return [self]
        #
        # @api public
        def boot(identifier = nil, key: nil, from: nil, namespace: nil, &block)
          if from.nil?
            raise(InvalidComponentIdentifierError, identifier) if identifier.nil?

            provider = Provider.new(
              identifier.to_sym,
              :__local__,
              definition: block,
              namespace: namespace
            )

            booter.register(provider)
            booter.boot(identifier, from: :__local__, namespace: namespace)
          else
            booter.boot(identifier, from: from, namespace: namespace, &block)
          end

          self
        end

        def start(identifier)
          booter.start(identifier)
        end

        def stop(identifier)
          booter.stop(identifier)
        end
      end
    end
  end
end
