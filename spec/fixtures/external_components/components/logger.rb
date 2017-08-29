require "dry/system"

Dry::System.register_component(:logger, provider: :external_components) do
  init do
    module ExternalComponents
      class Logger
        class << self
          attr_accessor :default_level
        end
      end
    end
  end

  start do
    register(:logger, ExternalComponents::Logger.new)
  end
end
