# frozen_string_literal: true

require "fileutils"
require "pathname"
require "tmpdir"

module RSpec
  module Support
    module TmpDirectory
      private

      def with_tmp_directory(&block)
        with_directory(make_tmp_directory, &block)
      end

      def with_directory(dir, &block)
        Dir.chdir(dir, &block)
      end

      def make_tmp_directory
        Pathname(Dir.mktmpdir).tap do |dir|
          (@made_tmp_dirs ||= []) << dir
        end
      end

      def write(path, *content)
        Pathname.new(path).dirname.mkpath

        File.open(path, ::File::CREAT | ::File::WRONLY) do |file|
          file.write(Array(content).flatten.join)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::TmpDirectory

  config.after :all do
    if instance_variable_defined?(:@made_tmp_dirs)
      Array(@made_tmp_dirs).each do |dir|
        FileUtils.remove_entry dir
      end
    end
  end
end
