module Dry
  module System
    module Plugins
      module DependencyGraph
        class Stratagies
          extend Dry::Container::Mixin

          class Kwargs < Dry::AutoInject::Strategies::Kwargs
          private

            def define_initialize(klass)
              puts "HERE #{dependency_map.to_h} : #{klass}"
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
