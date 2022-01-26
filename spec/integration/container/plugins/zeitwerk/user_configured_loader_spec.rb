# frozen_string_literal: true

RSpec.describe "Zeitwerk plugin / User-configured loader" do
  include ZeitwerkHelpers

  after { teardown_zeitwerk }

  it "uses the user-configured loader and pushes component dirs to it" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo;end
        end
      RUBY

      require "zeitwerk"

      logs = []

      container = Class.new(Dry::System::Container) do
        use :zeitwerk

        configure do |config|
          config.root = tmp_dir
          config.component_dirs.add "lib" do |dir|
            dir.namespaces.add_root const: "test"
          end

          config.autoloader = Zeitwerk::Loader.new.tap do |loader|
            loader.tag = "custom_loader"
            loader.logger = -> str { logs << str }
          end
        end
      end

      expect(container["foo"]).to be_a Test::Foo
      expect(logs).not_to be_empty
      expect(logs[0]).to include "custom_loader"
    end
  end
end
