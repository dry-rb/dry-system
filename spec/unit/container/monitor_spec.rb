# frozen_string_literal: true

RSpec.describe Dry::System::Container do
  subject(:system) do
    Class.new(Dry::System::Container) do
      use :monitoring
    end
  end

  describe ".monitor" do
    let(:klass) do
      Class.new do
        def self.name
          "Test::Class_#{__id__}"
        end

        def say(word, lang: nil, &block) # rubocop:disable Lint/UnusedMethodArgument
          block&.call
          word
        end

        def other; end
      end
    end

    let(:object) do
      klass.new
    end

    before do
      system.configure {}
      system.register(:object, klass.new)
    end

    it "monitors object public method calls" do
      captured = []

      system.monitor(:object) do |event|
        captured << [event.id, event[:target], event[:method], event[:args], event[:kwargs]]
      end

      object = system[:object]
      block_result = []
      block = proc { block_result << true }

      result = object.say("hi", lang: "en", &block)

      expect(block_result).to eql([true])
      expect(result).to eql("hi")

      expect(captured).to eql([[:monitoring, :object, :say, ["hi"], {lang: "en"}]])
    end

    it "monitors specified object method calls" do
      captured = []

      system.monitor(:object, methods: [:say]) do |event|
        captured << [event.id, event[:target], event[:method], event[:args], event[:kwargs]]
      end

      object = system[:object]

      object.say("hi")
      object.other

      expect(captured).to eql([[:monitoring, :object, :say, ["hi"], {}]])
    end
  end
end
