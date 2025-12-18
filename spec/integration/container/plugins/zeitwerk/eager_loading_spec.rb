# frozen_string_literal: true

# rubocop:disable Style/GlobalVars

RSpec.describe "Zeitwerk plugin / Eager loading" do
  before do
    $eager_loaded = false
    allow(Zeitwerk::Loader).to receive(:new).and_return(ZeitwerkLoaderRegistry.new_loader)
  end

  after { ZeitwerkLoaderRegistry.clear }

  it "Eager loads after finalization" do
    with_tmp_directory do |tmp_dir|
      write "lib/zeitwerk_eager.rb", <<~RUBY
        $eager_loaded = true

        module Test
          class ZeitwerkEager; end
        end
      RUBY

      container = Class.new(Dry::System::Container) do
        use :zeitwerk, eager_load: true

        configure do |config|
          config.root = tmp_dir
          config.component_dirs.add "lib" do |dir|
            dir.namespaces.add_root const: "test"
          end
        end
      end

      expect { container.finalize! }.to change { $eager_loaded }.to true
    end
  end

  it "Eager loads in production by default" do
    with_tmp_directory do |tmp_dir|
      write "lib/zeitwerk_eager.rb", <<~RUBY
        $eager_loaded = true

        module Test
          class ZeitwerkEager; end
        end
      RUBY

      container = Class.new(Dry::System::Container) do
        use :env, inferrer: -> { :production }
        use :zeitwerk

        configure do |config|
          config.root = tmp_dir
          config.component_dirs.add "lib" do |dir|
            dir.namespaces.add_root const: "test"
          end
        end
      end

      expect { container.finalize! }.to change { $eager_loaded }.to true
    end
  end
end

# rubocop:enable Style/GlobalVars
