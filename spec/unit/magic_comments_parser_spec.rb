# frozen_string_literal: true

require 'dry/system/magic_comments_parser'

RSpec.describe Dry::System::MagicCommentsParser, '.call' do
  let(:file_name) { SPEC_ROOT.join('fixtures/magic_comments/comments.rb') }
  let(:comments) { described_class.(file_name) }

  it 'makes comment names available as symbols' do
    expect(comments.key?(:valid_comment)).to eql true
  end

  it 'finds magic comments after other commented lines or blank lines' do
    expect(comments[:valid_comment]).to eq 'hello'
  end

  it 'does not match comments with invalid names' do
    expect(comments.values).not_to include 'value for comment using dashes'
  end

  it 'supports comment names with alpha-numeric characters and underscores (numbers not allowed for first character)' do
    expect(comments[:comment_123]).to eq 'alpha-numeric and underscores allowed'
    expect(comments.keys).not_to include(:"123_will_not_match")
  end

  it 'only matches comments at the start of the line' do
    expect(comments.key?(:not_at_start_of_line)).to eql false
  end

  it 'does not match any comments after any lines of code' do
    expect(comments.key?(:after_code)).to eql false
  end

  describe 'coercions' do
    it 'coerces "true" to true' do
      expect(comments[:true_comment]).to eq true
    end

    it 'coerces "false" to false' do
      expect(comments[:false_comment]).to eq false
    end
  end
end
