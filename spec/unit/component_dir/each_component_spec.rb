# frozen_string_literal: true

require "dry/system/component_dir"
require "dry/system/config/component_dir"
require "dry/system/container"

RSpec.describe Dry::System::ComponentDir, "#each_component" do
  subject(:components) { component_dir.each_component.to_a }

  let(:component_dir) {
    described_class.new(
      config: Dry::System::Config::ComponentDir.new(@dir.join("lib")) { |config|
        component_dir_config.(config) if defined?(component_dir_config)
      },
      container: container
    )
  }

  let(:container) {
    container_root = @dir

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = container_root
      end
    }
  }

  before :all do
    @dir = make_tmp_directory

    with_directory(@dir) do
      write "lib/test/component_file.rb"

      write "lib/test/component_file_with_auto_register_true.rb", <<~RUBY
        # auto_register: false
      RUBY

      write "lib/outside_namespace/component_file.rb"
    end
  end

  it "finds the components" do
    expect(components.length).to eq 3
  end

  it "returns components as Dry::System::Component" do
    expect(components).to all be_a Dry::System::Component
  end

  it "yields the components when called with a block" do
    expect { |b| component_dir.each_component(&b) }.to yield_successive_args(
      an_object_satisfying { |c| c.is_a?(Dry::System::Component) },
      an_object_satisfying { |c| c.is_a?(Dry::System::Component) },
      an_object_satisfying { |c| c.is_a?(Dry::System::Component) }
    )
  end

  it "prepares a matching key for each component" do
    expect(components.map(&:key)).to eq %w[
      outside_namespace.component_file
      test.component_file
      test.component_file_with_auto_register_true
    ]
  end

  context "component options given as component dir config" do
    let(:component_dir_config) {
      -> config {
        config.memoize = true
      }
    }

    it "includes the options with all components" do
      expect(components).to all satisfy(&:memoize?)
    end
  end

  context "component options given as magic comments" do
    let(:component) {
      components.detect { |c| c.key == "test.component_file_with_auto_register_true" }
    }

    it "loads the options specified within the magic comments" do
      expect(component.options).to include(auto_register: false)
    end
  end

  context "component options given as both component dir config and magic comments" do
    let(:component_dir_config) {
      -> config {
        config.auto_register = true
      }
    }

    let(:component) {
      components.detect { |c| c.key == "test.component_file_with_auto_register_true" }
    }

    it "prefers the options given as magic comments" do
      expect(component.options).to include(auto_register: false)
    end
  end

  context "namespaces configured" do
    let(:component_dir_config) {
      -> config {
        config.namespaces.add "test", identifier: nil
      }
    }

    it "loads the components in the order of the configured namespaces" do
      expect(components.map(&:key)).to eq %w[
        component_file
        component_file_with_auto_register_true
        outside_namespace.component_file
      ]
    end

    it "provides the namespace to each component" do
      expect(components[0].namespace.path).to eq "test"
      expect(components[1].namespace.path).to eq "test"
      expect(components[2].namespace.path).to be nil
    end
  end

  context "clashing component names in multiple namespaces" do
    before :all do
      @dir = make_tmp_directory
    end

    before :all do
      with_directory(@dir) do
        write "lib/ns1/component_file.rb"
        write "lib/ns2/component_file.rb"
      end
    end

    let(:component_dir_config) {
      -> config {
        config.namespaces.add "ns1", identifier: nil
        config.namespaces.add "ns2", identifier: nil
      }
    }

    it "returns all components, in order of configured namespaces, even with clashing keys" do
      expect(components.map(&:key)).to eq %w[
        component_file
        component_file
      ]

      expect(components[0].namespace.path).to eq "ns1"
      expect(components[1].namespace.path).to eq "ns2"
    end
  end
end
