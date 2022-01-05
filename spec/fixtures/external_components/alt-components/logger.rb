# frozen_string_literal: true

require "dry/system"

Dry::System.register_provider_source(:logger, group: :alt) do
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
