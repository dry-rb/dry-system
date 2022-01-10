# frozen_string_literal: true

Dry::System.register_source_provider(:settings, group: :system) do
  prepare do
    require "dry/system/settings"
  end

  start do |target_container|
    register(:settings, settings.init(target_container.root, target_container.config.env))
  end

  # WIP
  # define_exec_method :settings do
  # end
end
