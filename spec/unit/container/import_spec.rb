require 'dry/system/container'

RSpec.describe Dry::System::Container, '.import' do
  subject(:app) { Class.new(Dry::System::Container) }

  let(:db) do
    Class.new(Dry::System::Container) do
      register(:users, %w(jane joe))
    end
  end

  it 'imports one container into another' do
    app.import(persistence: db)

    expect(app.key?('persistence.users')).to be(false)

    app.finalize!

    expect(app['persistence.users']).to eql(%w(jane joe))
  end

  describe 'import module' do
    it 'loads system when it was not loaded in the imported container yet' do
      class Test::Other < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/import_test').realpath
        end

        load_paths!('lib')
      end

      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test').realpath
        end

        load_paths!('lib')

        import other: Test::Other
      end

      module Test
        Import = Container.injector
      end

      class Test::Foo
        include Test::Import['other.test.bar']
      end

      expect(Test::Foo.new.bar).to be_instance_of(Test::Bar)
    end
  end
end
