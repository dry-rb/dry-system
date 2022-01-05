# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_provider(:db, group: :alt) do
  init do
    module AltComponents
      class DbConn
      end
    end
  end

  start do
    register(:db_conn, AltComponents::DbConn.new)
  end
end
