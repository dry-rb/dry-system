RSpec.describe 'boot files' do
  subject(:system) { Test::Container }

  before do
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join('fixtures/test').realpath
      end
    end
  end

  it 'auto-boots dependency of a bootable component' do
    system.start(:client)

    expect(system[:client]).to be_a(Client)
    expect(system[:client].logger).to be_a(Logger)
  end
end
