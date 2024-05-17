# frozen_string_literal: true

RSpec.describe "Providers / Provider sources / Provider options" do
  let(:container) { Class.new(Dry::System::Container) }

  specify "provider_options registered with provider sources are used when creating corresponding providers" do
    Dry::System.register_provider_source(:db, group: :my_framework, provider_options: {namespace: true}) do
      start do
        register "config", "db_config_here"
      end
    end

    # Note no `namespace:` option when registering provider
    container.register_provider :db, from: :my_framework

    # Also works when using a different name for the provider
    container.register_provider :my_db, from: :my_framework, source: :db

    container.start :db
    container.start :my_db

    expect(container["db.config"]).to eq "db_config_here"
    expect(container["my_db.config"]).to eq "db_config_here"
  end

  specify "provider source provider_options can be overridden" do
    Dry::System.register_provider_source(:db, group: :my_framework, provider_options: {namespace: true}) do
      start do
        register "config", "db_config_here"
      end
    end

    container.register_provider :db, from: :my_framework, namespace: "custom_db"

    container.start :db

    expect(container["custom_db.config"]).to eq "db_config_here"
  end
end
