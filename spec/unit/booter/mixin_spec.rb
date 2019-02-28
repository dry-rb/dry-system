require 'dry/system/provider'

RSpec.describe Dry::System::Booter::Mixin do
  let(:booter_spy) { spy(:booter) }

  let(:container) do
    Class.new do
      extend Dry::Container::Mixin
      extend Dry::System::Booter::Mixin
    end.tap do |klass|
      booter = booter_spy
      klass.define_singleton_method(:booter) { booter }
    end
  end

  let(:provider_block) do
    ->(app){ start { register(:foo, "foo") } }
  end

  let(:finalize_block) do
    ->(app) { }
  end

  let(:local_provider) do
    Dry::System::Provider.new(:foo, :__local__, definition: provider_block, namespace: nil)
  end

  context 'a local provider' do
    it 'raises an error without an identifier' do
      expect {
        container.boot(nil, &provider_block)
      }.to raise_error(Dry::System::InvalidComponentIdentifierError)
    end

    it 'registers the provider with the booter and calls boot' do
      expect(booter_spy).to receive(:register).with(eq(local_provider))
      expect(booter_spy).to receive(:boot).with(:foo, hash_including(from: :__local__, namespace: nil))
      container.boot(:foo, &provider_block)
    end
  end

  context 'a system provider' do
    it 'delegates to the booter' do
      expect(booter_spy).to receive(:boot).with(:foo, hash_including(from: :system, namespace: nil))
      container.boot(:foo, from: :system, namespace: nil, &finalize_block)
    end
  end
end
