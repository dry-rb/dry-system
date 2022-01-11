# frozen_string_literal: true

require "dry/system"

Dry::System.register_provider_source(:db, group: :alt) do
  prepare do
    module AltComponents
      class DbConn
      end
    end
  end

  start do
    register(:db_conn, AltComponents::DbConn.new)
  end
end
