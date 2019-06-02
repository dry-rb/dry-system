# frozen_string_literal: true

require "dry/system"

Dry::System.register_component(:notifier, provider: :external_components) do
  init do
    module ExternalComponents
      class Notifier
        attr_reader :monitor

        def initialize(monitor)
          @monitor = monitor
        end
      end
    end
  end

  start do
    register(:notifier, ExternalComponents::Notifier.new(monitor))
  end
end
