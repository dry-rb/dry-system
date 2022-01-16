# frozen_string_literal: true

RSpec.describe "Providers / Registering components" do
  specify "Components registered with blocks in a provider are resolved as new objects each time in the target container" do
    module Test
      class Thing; end
    end

    container = Class.new(Dry::System::Container) do
      register_provider :thing, namespace: true do
        start do
          register :via_block do
            Test::Thing.new
          end

          register :direct, Test::Thing.new
        end
      end
    end

    container.start :thing

    thing_via_block_1 = container["thing.via_block"]
    thing_via_block_2 = container["thing.via_block"]

    thing_direct_1 = container["thing.direct"]
    thing_direct_2 = container["thing.direct"]

    expect(thing_via_block_1).to be_an_instance_of(thing_via_block_2.class)
    expect(thing_via_block_1).not_to be thing_via_block_2

    expect(thing_direct_1).to be thing_direct_2
  end

  specify "Components registered with options in a provider have those options set on the target container" do
    container = Class.new(Dry::System::Container) do
      register_provider :thing do
        start do
          register :thing, memoize: true do
            Object.new
          end
        end
      end
    end

    container.start :thing

    thing_1 = container["thing"]
    thing_2 = container["thing"]

    expect(thing_2).to be thing_1
  end

  specify "Components registered with keys that are already used on the target container are not applied" do
    container = Class.new(Dry::System::Container) do
      register_provider :thing, namespace: true do
        start do
          register :first, Object.new
          register :second, Object.new
        end
      end
    end

    already_registered = Object.new
    container.register "thing.second", already_registered

    container.start :thing

    expect(container["thing.first"]).to be
    expect(container["thing.second"]).to be already_registered
  end
end
