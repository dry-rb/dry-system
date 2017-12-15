RSpec.describe 'Plugins / Env' do
  context 'with default settings' do
    subject(:system) do
      Class.new(Dry::System::Container) do
        use :env
      end
    end

    describe '.env' do
      it 'returns :development' do
        expect(system.env).to be(:development)
      end
    end
  end

  context 'with a custom inferrer' do
    subject(:system) do
      Class.new(Dry::System::Container) do
        use :env, inferrer: -> { :test }
      end
    end

    describe '.env' do
      it 'returns :test' do
        expect(system.env).to be(:test)
      end
    end
  end
end
