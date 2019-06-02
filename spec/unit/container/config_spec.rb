# frozen_string_literal: true

require 'dry/system/container'

RSpec.describe Dry::System::Container, '.config' do
  subject(:config) { Test::Container.config }
  let(:configuration) { proc { } }

  before do
    class Test::Container < Dry::System::Container
    end
    Test::Container.configure(&configuration)
  end

  describe '#root' do
    subject(:root) { config.root }

    context 'no value' do
      it 'defaults to pwd' do
        expect(root).to eq Pathname.pwd
      end
    end

    context 'string provided' do
      let(:configuration) { proc { |config| config.root = '/tmp' } }

      it 'coerces string paths to pathname' do
        expect(root).to eq Pathname('/tmp')
      end
    end

    context 'pathname provided' do
      let(:configuration) { proc { |config| config.root = Pathname('/tmp') } }

      it 'accepts the pathname' do
        expect(root).to eq Pathname('/tmp')
      end
    end
  end
end
