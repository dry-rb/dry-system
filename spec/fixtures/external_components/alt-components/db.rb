# frozen_string_literal: true

require 'dry/system'

Dry::System.register_component(:db, provider: :alt) do
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
