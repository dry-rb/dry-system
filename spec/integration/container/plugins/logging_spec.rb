RSpec.describe 'Plugins / Logging' do
  before do
    system.configure do |config|
      config.root = SPEC_ROOT.join('fixtures/test')
    end
  end

  let(:logger) do
    system.logger
  end

  let(:log_file_content) do
    File.read(system.log_file_path)
  end

  context 'with default logger settings' do
    subject(:system) do
      Class.new(Dry::System::Container) do
        use :logging
      end
    end

    it 'logs to development.log' do
      logger.info "info message"

      expect(log_file_content).to include("info message")
    end
  end
end
