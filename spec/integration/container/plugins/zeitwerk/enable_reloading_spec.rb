# frozen_string_literal: true

RSpec.describe "Zeitwerk plugin / Enabling reloading" do
  before do
    allow(Zeitwerk::Loader).to receive(:new).and_return(ZeitwerkLoaderRegistry.new_loader)
  end

  after { ZeitwerkLoaderRegistry.clear }

  def build_container(tmp_dir, **plugin_options)
    Class.new(Dry::System::Container) do
      use :zeitwerk, **plugin_options

      configure do |config|
        config.root = tmp_dir
        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
        end
      end
    end
  end

  it "does not enable reloading by default" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo; end
        end
      RUBY

      container = build_container(tmp_dir)

      expect(container["foo"]).to be_a Test::Foo
      expect(container.autoloader.reloading_enabled?).to be false
      expect(container.autoloader.unloadable_cpaths).to be_empty
    end
  end

  it "enables reloading on the loader before it is set up" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo; end
        end
      RUBY

      container = build_container(tmp_dir, enable_reloading: true)

      expect(container["foo"]).to be_a Test::Foo
      expect(container.autoloader.reloading_enabled?).to be true
      expect(container.autoloader.unloadable_cpaths).to include "Test::Foo"
    end
  end

  it "enables reloading in time for a loader set up by the integrating library" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo; end
        end
      RUBY

      container = build_container(tmp_dir, run_setup: false, enable_reloading: true)

      # `run_setup: false` leaves `setup` to the integrating library, which must still find
      # reloading enabled: Zeitwerk only tracks unloadable constants when told ahead of `setup`.
      container.autoloader.setup

      expect(container["foo"]).to be_a Test::Foo
      expect(container.autoloader.reloading_enabled?).to be true
      expect(container.autoloader.unloadable_cpaths).to include "Test::Foo"
    end
  end

  it "allows the loaded constants to be unloaded and reloaded" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo
            def call = "original"
          end
        end
      RUBY

      container = build_container(tmp_dir, enable_reloading: true)

      expect(container["foo"].call).to eq "original"

      File.write(File.join(tmp_dir, "lib", "foo.rb"), <<~RUBY)
        module Test
          class Foo
            def call = "changed"
          end
        end
      RUBY

      container.autoloader.reload

      expect(Test::Foo.new.call).to eq "changed"
    end
  end
end
