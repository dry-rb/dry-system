# frozen_string_literal: true

module Dry
  module System
    module Plugins
      module DependencyGraph
        # @api private
        class Strategies
          extend Dry::Container::Mixin

          # @api private
          class Kwargs < Dry::AutoInject::Strategies::Kwargs
            private

            # @api private
            def define_initialize(klass)
              @container['notifications'].instrument(
                :resolved_dependency, dependency_map: dependency_map.to_h, target_class: klass
              )
              super(klass)
            end
          end

          register :kwargs, Kwargs
          register :default, Kwargs
        end
      end
    end
  end
end
