# frozen_string_literal: true

RSpec.describe "Providers / Resolving components with same root key as a running provider" do
  before :context do
    @dir = make_tmp_directory

    with_directory(@dir) do
      write "lib/animals/cat.rb", <<~RUBY
        module Test
          module Animals
            class Cat
              include Deps["animals.collar"]
            end
          end
        end
      RUBY

      write "lib/animals/collar.rb", <<~RUBY
        module Test
          module Animals
            class Collar; end
          end
        end
      RUBY

      write "system/providers/animals.rb", <<~RUBY
        Test::Container.register_provider :animals, namespace: true do
          start do
            require "animals/cat"
            register :cat, Test::Animals::Cat.new
          end
        end
      RUBY
    end
  end

  before do
    root = @dir
    Test::Container = Class.new(Dry::System::Container) do
      configure do |config|
        config.root = root
        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
        end
      end
    end

    Test::Deps = Test::Container.injector
  end

  context "lazy loading" do
    it "resolves the component without attempting to re-run provider steps" do
      expect(Test::Container["animals.cat"]).to be
    end
  end

  context "finalized" do
    before do
      Test::Container.finalize!
    end

    it "resolves the component without attempting to re-run provider steps" do
      expect(Test::Container["animals.cat"]).to be
    end
  end
end
