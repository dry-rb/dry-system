# frozen_string_literal: true

RSpec.describe "Plugins / Bootsnap" do
  subject(:system) do
    Class.new(Dry::System::Container) do
      use :bootsnap

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/test")
        config.env = :development
        config.bootsnap = {
          load_path_cache: false,
          compile_cache_iseq: true,
          compile_cache_yaml: true
        }
      end
    end
  end

  let(:cache_dir) do
    system.root.join("tmp/cache")
  end

  let(:bootsnap_cache_file) do
    cache_dir.join("bootsnap")
  end

  before do
    FileUtils.rm_rf(cache_dir)
    FileUtils.mkdir_p(cache_dir)
  end

  after do
    FileUtils.rm_rf(cache_dir)
  end

  describe ".require_from_root" do
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.4.0")
      it "loads file" do
        system.require_from_root("lib/test/models")

        expect(Object.const_defined?("Test::Models")).to be(true)

        expect(bootsnap_cache_file.exist?).to be(true)
      end
    end
  end
end
