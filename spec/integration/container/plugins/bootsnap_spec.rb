RSpec.describe 'Plugins / Bootsnap' do
  subject(:system) do
    Class.new(Dry::System::Container) do
      use :bootsnap

      configure do |config|
        config.root = SPEC_ROOT.join('fixtures/test')
        config.env = :development
      end
    end
  end

  let(:bootsnap_cache_file) do
    system.root.join('tmp/cache/bootsnap-load-path-cache')
  end

  after do
    FileUtils.rm_r(system.root.join('tmp/cache'))
  end

  describe '.require_from_root' do
    it 'loads file' do
      pending "bootsnap is not available" unless system.bootsnap_available?

      system.require_from_root('lib/test/models')

      expect(Object.const_defined?('Test::Models')).to be(true)

      expect(bootsnap_cache_file.exist?).to be(true)
    end
  end
end
