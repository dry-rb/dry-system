# frozen_string_literal: true

Dry::System.register_component(:settings, provider: :system) do
  init do
    require 'dry/system/settings'
  end

  start do
    register(:settings, settings.init(target.root, target.config.env))
  end
end
