# frozen_string_literal: true

RSpec.describe "Deprecated Dry::System::Container.import" do
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
end
