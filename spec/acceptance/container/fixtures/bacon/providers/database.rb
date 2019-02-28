require 'bacon/database'

module Test
  module Bacon
    register_provider(:database) do |app|
      settings do
        key :database_url, Types::String
      end

      init do
        register(:database, Database.new(config.database_url, app[:logger]))
      end
    end
  end
end
