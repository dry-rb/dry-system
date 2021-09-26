# frozen_string_literal: true

require "fileutils"
require "pathname"
require "tmpdir"
require_relative "with_directory"

module RSpec
  module Support
    # Execute the given code inside a temporary directory.
    #
    # NOTE: this changes the current `Dir.pwd`
    #
    # Adapted from hanami-devtools
    module WithTmpDirectory
      private

      def with_tmp_directory(dir = Dir.mktmpdir, &block)
        delete_tmp_directory(dir)
        create_tmp_directory(dir)

        with_directory(dir, &block)
      ensure
        delete_tmp_directory(dir)
      end

      def create_tmp_directory(dir)
        FileUtils.mkdir_p(dir)
      end

      def delete_tmp_directory(dir)
        directory = Pathname(dir)

        FileUtils.rm_rf(directory) if directory.exist?
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithTmpDirectory
end
