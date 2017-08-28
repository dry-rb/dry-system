RSpec.describe 'External Components' do
  subject(:container) do
    Class.new(Dry::System::Container) { register_external(:logger, provider: :external_components) }
  end

  before do
    require SPEC_ROOT.join('fixtures/external_components/lib/external_components')
  end

  context 'with default behavior' do
    it 'boots external logger component' do
      container.finalize!

      expect(container[:logger]).to be_instance_of(ExternalComponents::Logger)
    end
  end

  context 'with customized booting' do
    it 'exposes :init lifecycle step' do
      container.on(logger: :init) do
        ExternalComponents::Logger.default_level = :error
      end

      container.finalize!

      expect(container[:logger]).to be_instance_of(ExternalComponents::Logger)
      expect(container[:logger].class.default_level).to be(:error)
    end
  end

  context 'customized registration from an alternative provider' do
    subject(:container) do
      Class.new(Dry::System::Container) do
        register_external(:logger, provider: :external_components)
        register_external('alt.logger', provider: :alt, key: :logger)
      end
    end

    before do
      require SPEC_ROOT.join('fixtures/external_components/lib/external_components')
    end

    context 'with default behavior' do
      it 'boots external logger component from the specified provider' do
        container.finalize!

        expect(container[:logger]).to be_instance_of(ExternalComponents::Logger)
        expect(container['alt.logger']).to be_instance_of(AltComponents::Logger)
      end
    end
  end
end
