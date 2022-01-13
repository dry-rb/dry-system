# frozen_string_literal: true

require "dry/system/provider_sources/settings/loader"

RSpec.describe Dry::System::ProviderSources::Settings::Loader do
  subject(:loader) { described_class.new(root: root, env: env) }
  let(:root) { "/system/root" }
  subject(:env) { :development }

  before do
    allow_any_instance_of(described_class).to receive(:require).with("dotenv")
  end

  describe "#initialize" do
    context "dotenv available" do
      let(:dotenv) { spy(:dotenv) }

      before do
        stub_const "Dotenv", dotenv
      end

      context "non-test environment" do
        let(:env) { :development }

        it "requires dotenv and loads a range of .env files" do
          loader

          expect(loader).to have_received(:require).with("dotenv").ordered
          expect(dotenv).to have_received(:load).ordered.with(
            "/system/root/.env.development.local",
            "/system/root/.env.local",
            "/system/root/.env.development",
            "/system/root/.env"
          )
        end
      end

      context "test environment" do
        let(:env) { :test }

        it "loads a range of .env files, not including .env.local" do
          loader

          expect(dotenv).to have_received(:load).ordered.with(
            "/system/root/.env.test.local",
            "/system/root/.env.test",
            "/system/root/.env"
          )
        end
      end
    end

    context "dotenv unavailable" do
      it "attempts to require dotenv" do
        loader
        expect(loader).to have_received(:require).with("dotenv")
      end

      it "does not raise any error" do
        expect { loader }.not_to raise_error
      end
    end
  end

  describe "#[]" do
    it "returns a values from ENV" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SOME_KEY").and_return "some value"

      expect(loader["SOME_KEY"]).to eq "some value"
    end
  end
end
