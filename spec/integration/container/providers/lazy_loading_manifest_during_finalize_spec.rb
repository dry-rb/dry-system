# frozen_string_literal: true

RSpec.describe "Providers / Lazy loading a manifest-registered dependency as part of finalize" do
  before :context do
    @dir = make_tmp_directory

    with_directory(@dir) do
      write "system/registrations/deps.rb", <<~RUBY
        Test::Container.namespace(:deps) do |container|
          container.register(:thing) { Object.new }
        end
      RUBY
    end
  end

  before do
    root = @dir
    Test::Container = Class.new(Dry::System::Container) do
      configure do |config|
        config.root = root
      end

      register_provider :my_provider do
        start do
          target["deps.thing"]
        end
      end
    end
  end

  it "does not register the manifest dependency more than once" do
    expect { Test::Container.finalize! }.not_to raise_error
    expect(Test::Container["deps.thing"]).to be
  end
end
