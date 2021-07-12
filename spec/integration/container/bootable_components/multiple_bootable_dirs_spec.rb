# frozen_string_literal: true

RSpec.describe "Bootable components / Multiple bootable dirs" do
  specify "Resolving boot files from multiple bootable dirs" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/multiple_bootable_dirs").realpath
          config.bootable_dirs = [
            "custom_bootables", # Relative paths are appended to the container root
            SPEC_ROOT.join("fixtures/multiple_bootable_dirs/default_bootables")
          ]
        end

      end
    end

    expect(Test::Container[:inflector]).to eq "default_inflector"
    expect(Test::Container[:logger]).to eq "custom_logger"
  end
end
