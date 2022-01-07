# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_provider(:mailer, group: :external_components) do
  prepare do
    module ExternalComponents
      class Mailer
        attr_reader :client

        def initialize(client)
          @client = client
        end
      end
    end
  end

  start do |target_container|
    use :client

    register(:mailer, ExternalComponents::Mailer.new(target_container["client"]))
  end
end
