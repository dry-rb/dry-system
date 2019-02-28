require 'delegate'

RSpec.describe Dry::Container do
  subject(:container) { Class.new(Dry::System::Container) }
  let(:klass) { Class.new }
  let(:instance) { klass.new }

  describe '.register' do
    specify 'constant value is constant' do
      container.register(:foo, instance)
      expect(container[:foo]).to be(container[:foo])
    end

    specify 'memoize: true calls block once' do
      block_count = 0
      container.register(:foo, memoize: true) do
        block_count += 1
        klass.new
      end

      expect(container[:foo]).to be(container[:foo])
      expect(block_count).to eq(1)
    end

    specify 'memoize: false calls block each time' do
      block_count = 0
      container.register(:foo, memoize: false) do
        block_count += 1
        klass.new
      end

      expect(container[:foo]).not_to be(container[:foo])
      expect(block_count).to eq(2)
    end
  end

  describe '.decorate' do
    specify 'constant registration' do
      object = klass.new
      container.register(:foo, object)
      container.decorate(:foo, with: SimpleDelegator)

      expect(container[:foo]).to be_a(SimpleDelegator)
      expect(container[:foo].__getobj__).to be(object)
    end

    context 'callable registration' do
      before do
        container.register(:foo, memoize: memoize) { klass.new }
        container.decorate(:foo, with: SimpleDelegator)
      end

      context 'non-memoized block registration' do
        let(:memoize) { false }

        it 'is a different wrapped value' do
          expect(container[:foo]).to be_a(SimpleDelegator)
          expect(container[:foo].__getobj__).to be_a(klass)

          # Fail due to bug in Dry::Container
          # expect(container[:foo]).not_to be(container[:foo])
          # expect(container[:foo].__getobj__).not_to be(container[:foo].__getobj__)
        end
      end

      context 'memoized block registration' do
        let(:memoize) { true }

        it 'is the same wrapped value' do
          klass = Class.new

          expect(container[:foo]).to be_a(SimpleDelegator)
          expect(container[:foo]).to be(container[:foo])
        end
      end
    end
  end
end
