module Dry
  module System
    module Plugins
      class Manager
        attr_accessor :container

        def initialize(container, plugins = {})
          @container = container
          @registry = plugins.dup
          @started_plugins = {}
          @hook_cache = {}
        end

        def initialize_copy(other)
          other.instance_variable_set(:@registry, @registry.clone)
          other.instance_variable_set(:@hook_cache, {})
          other.instance_variable_set(:@started_plugins, {})
        end

        def key?(key)
          @registry.key?(key)
        end
        alias_method :has_key?, :key?

        def [](name)
          @started_plugins[name.to_sym]
        end

        def start!
          @registry.each do |identifier, plugin|
            @started_plugins[identifier] = plugin.new(container, {})

            reader = plugin.config.reader

            if reader
              reader = identifier if reader == true

              container.send(:define_singleton_method, reader) do
                plugins[identifier.to_sym].instance
              end
            end
          end
        end

        def use(plugin)
          identifier = plugin.config.identifier

          raise InvalidPluginError.new(plugin) if identifier.nil?

          @registry[identifier] = plugin

          plugin.used(container) if plugin.respond_to?(:used)
        end

        def key_missing(identified)
          @started_plugins.values.each do |plugin|
            if plugin.respond_to?(:key_missing)
              plugin.key_missing(identified)

              return true if container.key?(identified.identifier)
            end
          end

          false
        end

        def trigger_after_configure
          trigger(:configure, :after, container.config)
        end

        def trigger(event, phase = nil, *args)
          meth = (phase ? "#{phase}_#{event}" : event).to_sym

          unless @hook_cache.key?(meth)
            @hook_cache[meth] = @started_plugins.values.find_all { |plugin| plugin.respond_to?(meth) }
          end

          @hook_cache[meth].each do |plugin|
            plugin.send(meth, *args)
          end
        end
      end
    end
  end
end
