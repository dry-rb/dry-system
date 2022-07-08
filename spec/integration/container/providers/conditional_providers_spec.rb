# frozen_string_literal: true

RSpec.describe "Providers / Conditional providers" do
  let(:container) {
    provider_if = self.provider_if
    Class.new(Dry::System::Container) {
      register_provider :provided, if: provider_if do
        start do
          register "provided", Object.new
        end
      end
    }
  }

  shared_examples "loads the provider" do
    it "runs the provider when a related component is resolved" do
      expect(container["provided"]).to be
      expect(container.providers.key?(:provided)).to be true
    end
  end

  shared_examples "does not load the provider" do
    it "does not run the provider when a related component is resolved" do
      expect { container["provided"] }.to raise_error(Dry::Container::KeyError, /key not found: "provided"/)
      expect(container.providers.key?(:provided)).to be false
    end
  end

  describe "true" do
    let(:provider_if) { true }

    context "lazy loading" do
      include_examples "loads the provider"
    end

    context "finalized" do
      before { container.finalize! }
      include_examples "loads the provider"
    end
  end

  describe "false" do
    let(:provider_if) { false }

    context "lazy loading" do
      include_examples "does not load the provider"
    end

    context "finalized" do
      before { container.finalize! }
      include_examples "does not load the provider"
    end
  end

  describe "provider file in provider dir" do
    let(:container) {
      root = @dir
      Test::Container = Class.new(Dry::System::Container) {
        configure do |config|
          config.root = root
        end
      }
    }

    describe "true" do
      before :context do
        with_directory(@dir = make_tmp_directory) do
          write "system/providers/provided.rb", <<~RUBY
            Test::Container.register_provider :provided, if: true do
              start do
                register "provided", Object.new
              end
            end
          RUBY
        end
      end

      context "lazy loading" do
        include_examples "loads the provider"
      end

      context "finalized" do
        before { container.finalize! }
        include_examples "loads the provider"
      end
    end

    describe "true" do
      before :context do
        with_directory(@dir = make_tmp_directory) do
          write "system/providers/provided.rb", <<~RUBY
            Test::Container.register_provider :provided, if: false do
              start do
                register "provided", Object.new
              end
            end
          RUBY
        end
      end

      context "lazy loading" do
        include_examples "does not load the provider"
      end

      context "finalized" do
        before { container.finalize! }
        include_examples "does not load the provider"
      end
    end
  end
end
