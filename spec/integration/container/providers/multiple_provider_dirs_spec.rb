# frozen_string_literal: true

RSpec.describe "Providers / Multiple provider dirs" do
  specify "Resolving provider files from multiple provider dirs" do
    module Test
      class Container < Dry::System::Container
        config.root = SPEC_ROOT.join("fixtures/multiple_provider_dirs").realpath

        config.provider_dirs = [
          "custom_bootables", # Relative paths are appended to the container root
          SPEC_ROOT.join("fixtures/multiple_provider_dirs/default_bootables")
        ]
      end
    end

    expect(Test::Container[:inflector]).to eq "default_inflector"
    expect(Test::Container[:logger]).to eq "custom_logger"
  end
end
