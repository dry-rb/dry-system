# frozen_string_literal: true

module Dry
  module System
    module Plugins
      module DependencyGraph
        # @api private
        class Stratagies
          extend Dry::Container::Mixin

          # @api private
          def self.with_notifications(value)
            @notifications = value
            self
          end

          # @api private
          def self.__notifications__
            @notifications
          end

          # @api private
          class Kwargs < Dry::AutoInject::Strategies::Kwargs
            private

            # @api private
            def define_initialize(klass)
              notifications = ::Dry::System::Plugins::DependencyGraph::Stratagies.__notifications__
              notifications.instrument(
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
