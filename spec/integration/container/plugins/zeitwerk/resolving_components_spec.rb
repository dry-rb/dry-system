# frozen_string_literal: true

RSpec.describe "Zeitwerk plugin / Resolving components" do
  after { ZeitwerkLoaderRegistry.clear }

  specify "Resolving components using Zeitwerk" do
    with_tmp_directory do |tmp_dir|
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo
            def call
              Entities::FooEntity.new
            end
          end
        end
      RUBY

      write "lib/entities/foo_entity.rb", <<~RUBY
        module Test
          module Entities
            class FooEntity; end
          end
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

      foo = container["foo"]
      entity = foo.call

      expect(foo).to be_a Test::Foo
      expect(entity).to be_a Test::Entities::FooEntity
    end
  end
end
