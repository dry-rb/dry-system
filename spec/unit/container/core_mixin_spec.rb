require 'dry/system/container/core_mixin'

RSpec.describe Dry::System::Core::Mixin do
  subject(:container) { Test::Container }

  before do
    class Test::Container
      extend Dry::Container::Mixin
      extend Dry::System::Core::Mixin

      config.root = Pathname.new(__dir__).join('fixtures').realpath
    end
  end

  describe '.load_paths' do
    specify do
      container.load_paths!('load')

      require 'baz'

      expect(Test.const_defined?(:Baz)).to be(true)
    end
  end

  describe '.require_from_root' do
    it 'requires a single file' do
      container.require_from_root('foo')

      expect(Test.const_defined?(:Foo)).to be(true)
    end

    it 'requires many files when glob pattern is passed' do
      container.require_from_root('*.rb')

      expect(Test.const_defined?(:Foo)).to be(true)
      expect(Test.const_defined?(:Bar)).to be(true)
    end
  end
end
