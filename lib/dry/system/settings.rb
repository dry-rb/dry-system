require "dry/core/class_builder"
require "dry/types"
require "dry/struct"

require "dry/system/settings/file_loader"
require "dry/system/constants"

module Dry
  module System
    module Settings
      class DSL < BasicObject
        attr_reader :identifier

        attr_reader :schema

        def initialize(identifier, &block)
          @identifier = identifier
          @schema = {}
          instance_eval(&block)
        end

        def call
          Core::ClassBuilder.new(name: 'Configuration', parent: Settings::Configuration).call do |klass|
            schema.each do |key, type|
              klass.setting(key, type)
            end
          end
        end

        def key(name, type)
          schema[name] = type
        end
      end

      class Configuration < Dry::Struct
        def self.setting(*args)
          attribute(*args)
        end

        def self.load(root, env)
          env_data = load_files(root, env)

          attributes = schema.each_with_object({}) do |(key, type), h|
            value = ENV.fetch(key.to_s.upcase) { env_data[key.to_s.upcase] }
            h[key] = value if value
          end

          new(attributes)
        rescue Dry::Struct::Error => e
          # We remove [Configuration.new] since is an internal class and could mislead users
          part_to_avoid = (e.message.index(']')+2)...-1
          raise InvalidSettingValueError.new(e.message[part_to_avoid])
        end

        def self.load_files(root, env)
          FileLoader.new.(root, env)
        end
        private_class_method :load_files
      end
    end
  end
end
