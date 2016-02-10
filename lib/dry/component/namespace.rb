require 'forwardable'
require 'dry/component/container'

module Dry
  module Component
    module Namespace
      class <<self
        def extended(namespace)
          container = build(namespace)
          namespace.const_set(:Container, container)

          namespace.extend SingleForwardable
          namespace.def_delegators container,
                              :root, :require, :options, :[],
                              :register, :finalize, :namespace,
                              :configure, :finalize!
        end

        def build(namespace)
          Class.new(Dry::Component::Namespace::Container) do
            config.namespace = namespace
          end
        end
      end

      class Container < Dry::Component::Container
        setting :namespace

        class << self
          def auto_register!(dir, &block)
            super(['.',dir].join('/'), &block)
          end

          def Loader(key)
            key = key.to_s.gsub(/^[\/\.]+/, '')
            Component.Loader(key, config.namespace)
          end
        end
      end
    end
  end
end
