module Dry
  module System
    module Plugins
      # @api public
      module Decorate
        # @api public
        def decorate(key, decorator:)
          original = _container.delete(key.to_s)

          if original.is_a?(Dry::Container::Item) && original.options[:call] && decorator.is_a?(Class)
            register(key) do
              decorator.new(original.call)
            end
          else
            decorated = decorator.is_a?(Class) ? decorator.new(original) : decorator
            register(key, decorated)
          end
        end
      end
    end
  end
end
