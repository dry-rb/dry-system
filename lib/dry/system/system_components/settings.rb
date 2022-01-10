# frozen_string_literal: true

Dry::System.register_source_provider(:settings, group: :system) do
  prepare do
    require "dry/system/system_components/settings/settings"
  end

  start do
    register(:settings, settings.load(target_container.root, target_container.config.env).config)
  end

  define_method :settings do |&block|
    if block
      @settings_block = block
    elsif @settings_class
      @settings_class
    elsif @settings_block
      @settings_class = Class.new(Dry::System::SystemComponents::Settings::Settings, &@settings_block)
    end
  end
end
