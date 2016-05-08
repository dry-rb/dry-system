require 'dry/component/container'

RSpec.describe Dry::Component::Container, '.import' do
  subject(:app) { Class.new(Dry::Component::Container) }

  let(:db) do
    Class.new(Dry::Component::Container) do
      register(:users, %w(jane joe))
    end
  end

  shared_examples_for 'an extended container' do
    it 'imports one container into another' do
      expect(app.key?('persistence.users')).to be(false)

      app.finalize!

      expect(app['persistence.users']).to eql(%w(jane joe))
    end
  end

  context 'when a container has a name' do
    before do
      db.configure { |c| c.name = :persistence }
      app.import(db)
    end

    it_behaves_like 'an extended container'
  end

  context 'when container does not have a name' do
    before do
      app.import(persistence: db)
    end

    it_behaves_like 'an extended container'
  end

  describe 'import module' do
    it 'loads component when it was not loaded in the imported container yet' do
      class Test::Other < Dry::Component::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/import_test').realpath
        end

        load_paths!('lib')
      end

      class Test::Container < Dry::Component::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test').realpath
        end

        load_paths!('lib')

        import other: Test::Other
      end

      module Test
        Import = Container.Inject
      end

      class Test::Foo
        include Test::Import['other.test.bar']
      end

      expect(Test::Foo.new.bar).to be_instance_of(Test::Bar)
    end
  end
end
