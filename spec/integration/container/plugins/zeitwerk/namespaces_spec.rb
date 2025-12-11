# frozen_string_literal: true

RSpec.describe "Zeitwerk plugin / Namespaces" do
  after { ZeitwerkLoaderRegistry.clear }

  it "loads components from a root namespace with a const namespace" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo; end
        end
      RUBY

      container = Class.new(Dry::System::Container) do
        use :zeitwerk

        configure do |config|
          config.root = tmp_dir

          config.component_dirs.add "lib" do |dir|
            dir.namespaces.add_root const: "test"
          end
        end
      end

      expect(container["foo"]).to be_an_instance_of Test::Foo
    end
  end

  it "loads components from multiple namespace with distinct const namespaces" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo; end
        end
      RUBY

      write "lib/nested/foo.rb", <<~RUBY
        module Test
          module Nested
            class Foo; end
          end
        end
      RUBY

      write "lib/adapters/bar.rb", <<~RUBY
        module My
          module Adapters
            class Bar; end
          end
        end
      RUBY

      container = Class.new(Dry::System::Container) do
        use :zeitwerk

        configure do |config|
          config.root = tmp_dir

          config.component_dirs.add "lib" do |dir|
            dir.namespaces.add "adapters", const: "my/adapters"
            dir.namespaces.add_root const: "test"
          end
        end
      end

      expect(container["foo"]).to be_an_instance_of Test::Foo
      expect(container["nested.foo"]).to be_an_instance_of Test::Nested::Foo
      expect(container["adapters.bar"]).to be_an_instance_of My::Adapters::Bar
    end
  end
end
