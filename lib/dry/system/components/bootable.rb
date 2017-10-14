require 'dry/system/lifecycle'
require 'dry/system/settings'
require 'dry/system/components/config'

module Dry
  module System
    module Components
      class Bootable
        DEFAULT_FINALIZE = proc {}

        attr_reader :identifier

        attr_reader :finalize

        attr_reader :options

        attr_reader :triggers

        attr_reader :config

        attr_reader :namespace

        def initialize(identifier, options = {}, &block)
          @identifier = identifier
          @triggers = { before: Hash.new { |h, k| h[k] = [] }, after: Hash.new { |h, k| h[k] = [] } }
          @options = block ? options.merge(block: block) : options
          @namespace = options[:namespace]
          finalize = options[:finalize] || DEFAULT_FINALIZE
          instance_exec(&finalize)
        end

        def block
          options.fetch(:block)
        end

        def lifecycle
          @lifecycle ||= Lifecycle.new(lf_container, component: self, &block)
        end

        def lf_container
          container = Dry::Container.new

          case namespace
          when String, Symbol
            container.namespace(namespace) { |c| return c }
          when true
            container.namespace(identifier) { |c| return c }
          when nil
            container
          else
            raise RuntimeError, "+namespace+ boot option must be true, string or symbol #{namespace.inspect} given."
          end
        end

        def init
          lifecycle.(:init)
          trigger(:after, :init)
          self
        end

        def start
          lifecycle.(:start)
          trigger(:after, :start)
          self
        end

        def stop
          lifecycle.(:stop)
          self
        end

        def finalize
          lifecycle.container.each do |key, item|
            container.register(key, item) unless container.key?(key)
          end
          self
        end

        def trigger(key, event)
          triggers[key][event].each do |fn|
            container.instance_exec(lifecycle.container, &fn)
          end
          self
        end

        def after(event, &block)
          triggers[:after][event] << block
          self
        end

        def configure(&block)
          @config = settings.new(Config.new(&block)) if settings
        end

        def settings(&block)
          if block
            @settings = Settings::DSL.new(identifier, &block).call
          else
            @settings
          end
        end

        def config
          if @config
            @config
          else
            configure
          end
        end

        def container
          options.fetch(:container)
        end

        def with(new_options)
          self.class.new(identifier, options.merge(new_options))
        end

        def statuses
          lifecycle.statuses
        end

        def boot?
          true
        end

        def boot_file
          container_boot_files.
            detect { |path| Pathname(path).basename('.rb').to_s == identifier.to_s }
        end

        def boot_path
          container.boot_path
        end

        def container_boot_files
          Dir[container.boot_path.join('**/*.rb')]
        end
      end
    end
  end
end
