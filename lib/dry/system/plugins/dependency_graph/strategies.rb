module Dry
  module System
    module Plugins
      module DependencyGraph
        class Stratagies
          extend Dry::Container::Mixin

          def self.with_notifications(value)
            @notifications = value
            self
          end

          def self.__notifications__
            @notifications
          end

          class Kwargs < Dry::AutoInject::Strategies::Kwargs
          private

            def define_initialize(klass)
              notifications = ::Dry::System::Plugins::DependencyGraph::Stratagies.__notifications__
              notifications.instrument(:resolved_dependency, dependency_map: dependency_map.to_h, target_class: klass)
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
