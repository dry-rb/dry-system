# frozen_string_literal: true

RSpec.describe "Providers / Custom provider registrar" do
  specify "Customizing the target_container for providers" do
    # Create a provider registrar that exposes a container _wrapper_ (i.e. something resembling a
    # Hanami slice) as the target_container.
    provider_registrar = Class.new(Dry::System::ProviderRegistrar) do
      def self.for_wrapper(wrapper)
        Class.new(self) do
          define_singleton_method(:new) do |container|
            super(container, wrapper)
          end
        end
      end

      attr_reader :wrapper

      def initialize(container, wrapper)
        super(container)
        @wrapper = wrapper
      end

      def target_container
        wrapper
      end
    end

    # Create the wrapper, which has an internal Dry::System::Container (configured with our custom
    # provider_registrar) that it then delegates to.
    container_wrapper = Class.new do
      define_singleton_method(:container) do
        @container ||= Class.new(Dry::System::Container).tap do |container|
          container.config.provider_registrar = provider_registrar.for_wrapper(self)
        end
      end

      def self.register_provider(...)
        container.register_provider(...)
      end

      def self.start(...)
        container.start(...)
      end
    end

    # Create a provider to expose its given `target` so we can make expecations about it
    exposed_target = nil
    container_wrapper.register_provider(:my_provider) do
      start do
        exposed_target = target
      end
    end
    container_wrapper.start(:my_provider)

    expect(exposed_target).to be container_wrapper
  end
end
