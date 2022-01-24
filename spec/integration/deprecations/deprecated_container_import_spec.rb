# frozen_string_literal: true

RSpec.describe "Deprecated Dry::System::Container.import" do
  before do
    Object.send(:remove_const, :ExternalComponents) if defined? ExternalComponents
    require SPEC_ROOT.join("fixtures/external_components/lib/external_components")

    # We don't care about the deprecation messages when we're not testing for them
    # specifically
    Dry::Core::Deprecations.set_logger!(StringIO.new)
  end

  describe "container imports" do
    let(:exporting_container) {
      Class.new(Dry::System::Container) {
        register "foo", "foo"
      }
    }

    let(:importing_container) {
      exporting_container = self.exporting_container

      Class.new(Dry::System::Container) {
        import other: exporting_container, again: exporting_container
      }
    }

    it "registers the container for import" do
      expect(importing_container["other.foo"]).to eq "foo"
      expect(importing_container["again.foo"]).to eq "foo"
    end

    it "prints deprecation warnings" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      importing_container

      logger.rewind
      expect(logger.string).to match(/Dry::System::Container\.import with \{namespace => container\} hash is deprecated/m)
    end
  end
end
