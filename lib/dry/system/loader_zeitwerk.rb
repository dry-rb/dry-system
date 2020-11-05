# frozen_string_literal: true

require_relative "loader"

module Dry
  module System
    class LoaderZeitwerk < Loader
      def require!
        puts "Not requiring, zeitwerk has our back"
        # require path
      end
    end
  end
end
