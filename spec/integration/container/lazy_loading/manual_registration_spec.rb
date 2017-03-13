RSpec.describe 'Lazy-loading manual registration files' do
  before do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/manual_registration').realpath
        end

        load_paths!('lib')
      end
    end
  end

  it 'loads a manual registration file if the component could not be found' do
    expect(Test::Container['foo.special']).to be_a(Test::Foo)
    expect(Test::Container['foo.special'].name).to eq "special"
  end
end
