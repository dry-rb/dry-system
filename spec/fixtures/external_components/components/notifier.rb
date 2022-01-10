# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_provider(:notifier, group: :external_components) do
  prepare do
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
    register(:notifier, ExternalComponents::Notifier.new(target_container["monitor"]))
  end
end
