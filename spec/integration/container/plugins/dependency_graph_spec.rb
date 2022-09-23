# frozen_string_literal: true

RSpec.describe "Plugins / Dependency Graph" do
  let(:container) { Test::Container }
  subject(:events) { [] }

  before :context do
    with_directory(@dir = make_tmp_directory) do
      write "system/providers/mailer.rb", <<~RUBY
        Test::Container.register_provider :mailer do
          start do
            register "mailer", Object.new
          end

        end
      RUBY

      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo
            include Deps["mailer"]
          end
        end
      RUBY

      write "lib/bar.rb", <<~RUBY
        module Test
          class Bar
            include Deps["foo"]
          end
        end
      RUBY
    end
  end

  before do
    root = @dir
    Test::Container = Class.new(Dry::System::Container) {
      use :dependency_graph

      configure! do |config|
        config.root = root
        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
        end
      end
    }
  end

  before do
    container[:notifications].subscribe(:resolved_dependency) { events << _1 }
    container[:notifications].subscribe(:registered_dependency) { events << _1 }
  end

  shared_examples "dependency graph notifications" do
    context "lazy loading" do
      it "emits dependency notifications for the resolved component" do
        container["foo"]

        expect(events.map { [_1.id, _1.payload] }).to eq [
          [:resolved_dependency, {dependency_map: {mailer: "mailer"}, target_class: Test::Foo}],
          [:registered_dependency, {class: Object, key: "mailer"}],
          [:registered_dependency, {class: Test::Foo, key: "foo"}]
        ]
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it "emits dependency notifications for all components" do
        expect(events.map { [_1.id, _1.payload] }).to eq [
          [:registered_dependency, {key: "mailer", class: Object}],
          [:resolved_dependency, {dependency_map: {foo: "foo"}, target_class: Test::Bar}],
          [:resolved_dependency, {dependency_map: {mailer: "mailer"}, target_class: Test::Foo}],
          [:registered_dependency, {key: "foo", class: Test::Foo}],
          [:registered_dependency, {key: "bar", class: Test::Bar}]
        ]
      end
    end
  end

  describe "default (kwargs) injector" do
    before do
      Test::Deps = Test::Container.injector
    end

    specify "objects receive dependencies via keyword arguments" do
      expect(container["bar"].method(:initialize).parameters).to eq(
        [[:keyrest, :kwargs], [:block, :block]]
      )
    end

    it_behaves_like "dependency graph notifications"
  end

  describe "hash injector" do
    before do
      Test::Deps = Test::Container.injector.hash
    end

    specify "objects receive dependencies via a single options hash argument" do
      expect(container["bar"].method(:initialize).parameters).to eq [[:req, :options]]
    end

    it_behaves_like "dependency graph notifications"
  end

  describe "args injector" do
    before do
      Test::Deps = Test::Container.injector.args
    end

    specify "objects receive dependencies via positional arguments" do
      expect(container["bar"].method(:initialize).parameters).to eq [[:req, :foo]]
    end

    it_behaves_like "dependency graph notifications"
  end
end
