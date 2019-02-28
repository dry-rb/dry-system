require 'dry/system/settings'
require 'dry/system/booter/config'

module Dry
  module System
    module Booter
      # Lifecycle booting DSL
      #
      # Lifecycle objects are used in the boot files where you can register custom
      # init/start/stop triggers
      #
      # @see [Container.finalize]
      #
      # @api private
      class Lifecycle
        StateError = Class.new(StandardError) do
          def initialize(provider, method, state)
            super("Tried to #{method} #{provider} from state #{state}")
          end
        end

        attr_reader :identifier, :provider, :container, :statuses, :state

        %w{registered booted inited started stopped}.each do |meth|
          define_method("#{meth}?") { @state == meth.to_sym }
        end

        # @api private
        def initialize(identifier, provider, container = Dry::Container.new)
          @identifier = identifier
          @provider = provider
          @container = container
          @statuses = []
          @state = :registered
        end

        def provide?(key)
          key = TO_SYM_ARRAY[key]
          provider.provides.include?(key)
        end

        def provides
          provider.provides.map do |key|
            key.size == 1 ? key.first : key.join('.')
          end
        end

        def settings
          @settings ||= provider.settings_block && Settings::DSL.new(provider.identifier, &provider.settings_block).call
        end

        def config
          @config ||= provider.configure_block && settings&.new(Config.new(&provider.configure_block).to_hash)
        end

        # @api private
        def register(*args, &block)
          begin
            container.register(*args, &block)
          rescue Dry::Container::Error
          end
        end

        def trigger(key, event)
          statuses << "#{event}_#{key}"

          provider.triggers[key][event].each do |fn|
            instance_exec(container, &fn)
          end

          self
        end

        def boot
          raise StateError.new(provider, :init, @state) unless @state == :registered

          trigger(:before, :boot)
          instance_exec(container, &provider.boot_block) if provider.boot_block
          trigger(:after, :boot)


          @state = :booted

          self
        end

        # @api private
        def init
          raise StateError.new(provider, :init, @state) unless @state == :booted

          trigger(:before, :init)
          instance_exec(container, &provider.init_block) if provider.init_block
          trigger(:after, :init)

          @state = :inited

          self
        end

        # @api private
        def start
          raise StateError.new(provider, :start, @state) unless @state == :inited || @state == :stopped

          trigger(:before, :start)
          instance_exec(container, &provider.start_block) if provider.start_block
          trigger(:after, :start)

          @state = :started

          self
        end

        # @api private
        def stop
          raise StateError.new(provider, :stop, @state) unless @state == :started

          trigger(:before, :stop)
          instance_exec(container, &provider.stop_block) if provider.stop_block
          trigger(:after, :stop)

          @state = :stopped

          self
        end
      end
    end
  end
end