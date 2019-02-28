require 'dry/system_plugins/env/parser'

RSpec.describe Dry::SystemPlugins::Env::Parser do
  subject(:parser) { Dry::SystemPlugins::Env::Parser }

  specify 'valid file parses and ignores gibberish' do
    file = <<-FILE
    FOOBAR=bazbar
    BAZBAR = foobar
    weafewfewfwefew
    FILE

    expect(parser[file]).to eq({
      'FOOBAR' => 'bazbar',
      'BAZBAR' => 'foobar'
    })
  end
end
