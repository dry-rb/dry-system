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
          errors = {}
          attributes = {}

          schema.each do |key, type|
            value = ENV.fetch(key.to_s.upcase) { env_data[key.to_s.upcase] }
            result = check_value_against_type?(type, value)

            errors[key] = result if result.failure?
            attributes[key] = value if value
          end

          raise InvalidSettingsError.new(errors) unless errors.empty?

          new(attributes)
        end

        def self.load_files(root, env)
          FileLoader.new.(root, env)
        end
        private_class_method :load_files

        def self.check_value_against_type?(type, value)
          value ? type.try(value) : type.try(Undefined)
        end
      end
    end
  end
end
