# frozen_string_literal: true

require "dry/system/errors"

RSpec.describe "Dry::System::Errors" do
  describe Dry::System::ComponentNotLoadableError do
    let(:component) { instance_double(Dry::System::Component, key: key) }
    let(:error) { instance_double(NameError, name: "Foo", receiver: "Test") }
    subject { described_class.new(component, error, corrections: corrections) }

    describe "without corrections" do
      let(:corrections) { [] }
      let(:key) { "test.foo" }

      it do
        expect(subject.message).to eq(
          "Component 'test.foo' is not loadable.\n" \
          "Looking for Test::Foo."
        )
      end
    end

    describe "with corrections" do
      describe "acronym" do
        describe "single class name correction" do
          let(:corrections) { ["Test::FOO"] }
          let(:key) { "test.foo" }

          it do
            expect(subject.message).to eq(
              <<~ERROR_MESSAGE
                Component 'test.foo' is not loadable.
                Looking for Test::Foo.

                You likely need to add:

                    acronym('FOO')

                to your container's inflector, since we found a Test::FOO class.
              ERROR_MESSAGE
            )
          end
        end

        describe "module and class name correction" do
          let(:error) { instance_double(NameError, name: "Foo", receiver: "Test::Api") }
          let(:corrections) { ["Test::API::FOO"] }
          let(:key) { "test.api.foo" }

          it do
            expect(subject.message).to eq(
              <<~ERROR_MESSAGE
                Component 'test.api.foo' is not loadable.
                Looking for Test::Api::Foo.

                You likely need to add:

                    acronym('API', 'FOO')

                to your container's inflector, since we found a Test::API::FOO class.
              ERROR_MESSAGE
            )
          end
        end
      end

      describe "typo" do
        let(:corrections) { ["Test::Fon", "Test::Flo"] }
        let(:key) { "test.foo" }

        it do
          expect(subject.message).to eq(
            <<~ERROR_MESSAGE.chomp
              Component 'test.foo' is not loadable.
              Looking for Test::Foo.

              Did you mean?  Test::Fon
                             Test::Flo
            ERROR_MESSAGE
          )
        end
      end
    end
  end

  describe Dry::System::CyclicDependencyError do
    describe "ASCII art generation" do
      context "with two components" do
        it "generates simple bidirectional arrow" do
          error = described_class.new(%w[foo bar])

          expect(error.message).to include("These dependencies form a cycle:")
          expect(error.message).to include("foo ◄──► bar")
          expect(error.message).to include("You must break this cycle")
        end
      end

      context "with three components" do
        it "generates cycle visualization" do
          error = described_class.new(%w[alpha beta gamma])

          expect(error.message).to include("These dependencies form a cycle:")
          expect(error.message).to include("alpha ───► beta")
          expect(error.message).to include("beta ───► gamma")
          expect(error.message).to include("gamma ───► alpha")
          expect(error.message).to include("You must break this cycle")
        end
      end

      context "with longer cycle" do
        it "generates compact visualization" do
          cycle = %w[service_a service_b service_c service_d service_e]
          error = described_class.new(cycle)

          expect(error.message).to include("These dependencies form a cycle:")
          expect(error.message).to include("service_a ───► service_b ───► service_c ───► service_d ───► service_e ───► service_a")
          expect(error.message).to include("You must break this cycle")
        end
      end

      context "with empty cycle" do
        it "handles empty cycle gracefully" do
          error = described_class.new([])

          expect(error.message).to include("These dependencies form a cycle:")
          expect(error.message).to include("You must break this cycle")
        end
      end
    end
  end
end
