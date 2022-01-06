# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_provider(:logger, group: :alt) do
  prepare do
    module AltComponents
      class Logger
      end
    end
  end

  start do
    register(:logger, AltComponents::Logger.new)
  end
end
