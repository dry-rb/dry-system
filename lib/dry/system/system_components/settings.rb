Dry::System.register_component(:settings, provider: :system_components) do
  init do
    require 'dry/system/settings'
  end

  start do
    register(:settings, settings.load(target.root, target.env))
  end
end
