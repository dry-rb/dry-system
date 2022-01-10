# frozen_string_literal: true

require "dry/configurable"
require "dry/system/settings/file_loader"


module Dry
  module System
    module SystemComponents
      class Settings
        include Dry::Configurable

        class << self
          def load(root, env)
            env_data = load_files(root, env)
            attributes = {}
            errors = {}

            settings.to_a.each do |setting_name|
              value = ENV.fetch(setting_name.to_s.upcase) { env_data[setting_name.to_s.upcase] }
              # TODO: restore type checks
              # type_check = key.try(value || Undefined)
              # errors[key] = type_check if type_check.failure?
              attributes[setting_name] = value if value
            end

            # TODO: restore
            # raise InvalidSettingsError, errors unless errors.empty?

            new.tap do |obj|
              attributes.each do |name, val|
                obj.config.send(:"#{name}=", val)
              end
            end
          end

          private

          def load_files(root, env)
            Dry::System::Settings::FileLoader.new.(root, env)
          end
        end
      end
    end
  end
end

Dry::System.register_source_provider(:settings, group: :system) do
  prepare do
    puts "PREPAREEEEEE"
    # byebug
    require "dry/system/settings"
  end

  start do
    puts "STARTTTT"
    # byebug
    # register(:settings, settings.init(target_container.root, target_container.config.env))
    register(:settings, settings.load(target_container.root, target_container.config.env).config)
  end

  source_class.define_method :settings do |&block|
    if block
      puts "saving block"
      @settings_block = block
      # @settings_class = Class.new(Dry::System::SystemComponents::Settings, &block)
    elsif @settings_class
      puts "settings class is ready, here you are"
      @settings_class
    elsif @settings_block
      puts "building and returning settings class"
      @settings_class = Class.new(Dry::System::SystemComponents::Settings, &@settings_block)
    end
  end
end
