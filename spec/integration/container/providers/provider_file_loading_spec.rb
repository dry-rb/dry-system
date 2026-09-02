# frozen_string_literal: true

RSpec.describe "Providers / Loading provider files" do
  before do
    module Test
      class << self
        attr_accessor :container, :message
      end
    end

    Test.message = "hello"

    @dir = make_tmp_directory

    write_provider <<~RUBY
      Test.container.register_provider(:greeter) do
        start { register(:greeter, Test.message) }
      end
    RUBY
  end

  def write_provider(content)
    dir = File.join(@dir, "system", "providers")
    FileUtils.mkdir_p(dir)

    File.write(File.join(dir, "greeter.rb"), content)
  end

  def build_container
    root = @dir

    Class.new(Dry::System::Container) do
      config.root = root
    end
  end

  specify "a provider file is evaluated once per container, not once per process" do
    Test.container = build_container
    expect(Test.container[:greeter]).to eq "hello"

    # A second container sharing the provider dir must get its own provider, rather than having
    # the file skipped because the first container already loaded it.
    Test.container = build_container
    expect(Test.container[:greeter]).to eq "hello"
  end

  specify "a container built afresh picks up changes to a provider file" do
    Test.container = build_container
    expect(Test.container[:greeter]).to eq "hello"

    write_provider <<~RUBY
      Test.container.register_provider(:greeter) do
        start { register(:greeter, Test.message.upcase) }
      end
    RUBY

    Test.container = build_container
    expect(Test.container[:greeter]).to eq "HELLO"
  end

  specify "a provider file is evaluated at most once for a given container" do
    # The provider name does not match the file name, so looking up `:greeter` loads the file
    # without ever finding the provider it was looking for.
    write_provider <<~RUBY
      Test.container.register_provider(:other_name) do
        start { register(:greeter, Test.message) }
      end
    RUBY

    Test.container = build_container

    expect(Test.container.providers[:greeter]).to be_nil

    # Loading the file a second time would re-register `:other_name` and raise.
    expect { Test.container.providers[:greeter] }.not_to raise_error
  end
end
