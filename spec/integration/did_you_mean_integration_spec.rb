# frozen_string_literal: true

require "ostruct"

RSpec.describe "DidYouMean integration" do
  subject(:system) { Test::Container }

  context "with a file with a syntax error in it" do
    before do
      class Test::Container < Dry::System::Container
        use :zeitwerk

        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").join("components_with_errors").realpath
          config.component_dirs.add "test"
        end
      end
    end

    it "auto-boots dependency of a bootable component" do
      expect { system["constant_error"] }
        .to raise_error(NameError, "uninitialized constant ConstantError::NotHere")
    end
  end
end
