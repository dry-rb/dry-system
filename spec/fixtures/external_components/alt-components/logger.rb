# frozen_string_literal: true

require 'dry/system'

Dry::System.register_component(:logger, provider: :alt) do
  init do
    module AltComponents
      class Logger
      end
    end
  end

  start do
    register(:logger, AltComponents::Logger.new)
  end
end
