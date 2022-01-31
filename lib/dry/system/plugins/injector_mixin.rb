# frozen_string_literal: true

module Dry
  module System
    module Plugins
      # @api private
      class InjectorMixin < Module
        MODULE_SEPARATOR = "::"

        attr_reader :name

        def initialize(name: "Deps")
          @name = name
        end

        def extended(container)
          container.after(:configure, &method(:define_mixin))
        end

        private

        def define_mixin(container)
          inflector = container.config.inflector

          name_parts = name.split(MODULE_SEPARATOR)

          if name_parts[0] == ""
            name_parts.delete_at(0)
            root_module = Object
          else
            root_module = container_parent_module(container)
          end

          mixin_parent_mod = define_parent_modules(
            root_module,
            name_parts,
            inflector
          )

          mixin_parent_mod.const_set(
            inflector.camelize(name_parts.last),
            container.injector
          )
        end

        def container_parent_module(container)
          if container.name
            parent_name = container.name.split(MODULE_SEPARATOR)[0..-2].join(MODULE_SEPARATOR)
            container.config.inflector.constantize(parent_name)
          else
            Object
          end
        end

        def define_parent_modules(root_mod, name_parts, inflector)
          return root_mod if name_parts.length == 1

          name_parts[0..-2].reduce(root_mod) { |parent_mod, mod_name|
            parent_mod.const_set(inflector.camelize(mod_name), Module.new)
          }
        end
      end
    end
  end
end
