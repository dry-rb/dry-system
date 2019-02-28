require 'dry/system/settings'

SystemComponents.register_provider(:settings) do |app|
  start do
    register(:settings, settings.load(app.env))
  end
end
