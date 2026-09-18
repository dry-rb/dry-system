# frozen_string_literal: true

RSpec.describe "Providers / Loading provider files" do
  before do
    @dir = make_tmp_directory

    write_provider <<~RUBY
      Test::Container.register_provider(:greeter) do
        start { register(:greeter, "hello") }
      end
    RUBY
  end

  def write_provider(content)
    with_directory(@dir) do
      write "system/providers/greeter.rb", content
    end
  end

  # Mimics a container being unloaded and then reloaded, as a code reloader does: the container
  # class is discarded, then defined again under the same name.
  def load_container
    Test.send(:remove_const, :Container) if Test.const_defined?(:Container, false)

    root = @dir

    container = Class.new(Dry::System::Container) do
      config.root = root
    end

    Test.const_set(:Container, container)
  end

  specify "a reloaded container registers its providers again" do
    expect(load_container[:greeter]).to eq "hello"

    # The provider file is evaluated once per container, rather than once per process, so a new
    # container still gets this provider.
    expect(load_container[:greeter]).to eq "hello"
  end

  specify "a reloaded container picks up changes to a provider file" do
    expect(load_container[:greeter]).to eq "hello"

    write_provider <<~RUBY
      Test::Container.register_provider(:greeter) do
        start { register(:greeter, "HELLO") }
      end
    RUBY

    expect(load_container[:greeter]).to eq "HELLO"
  end

  specify "a provider file is evaluated at most once for a given container" do
    # The provider name does not match the file name, so looking up `:greeter` loads the file
    # without ever finding the provider it was looking for.
    write_provider <<~RUBY
      Test::Container.register_provider(:other_name) do
        start { register(:greeter, "hello") }
      end
    RUBY

    container = load_container

    expect(container.providers[:greeter]).to be_nil

    # Loading the file a second time would re-register `:other_name` and raise.
    expect { container.providers[:greeter] }.not_to raise_error
  end
end
