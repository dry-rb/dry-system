# frozen_string_literal: true

require "dry/system/cyclic_dependency_detector"

RSpec.describe Dry::System::CyclicDependencyDetector do
  subject(:detector) { described_class.new(backtrace) }
  let(:backtrace) { [] }

  describe ".detect_from_backtrace" do
    let(:backtrace) { ["/path/to/foo.rb:10:in `initialize'"] }

    it "delegates to instance method" do
      expect(described_class.detect_from_backtrace(backtrace)).to eq([])
    end
  end

  describe "#detect_cycle" do
    context "with no component files in backtrace" do
      let(:backtrace) do
        [
          "/usr/lib/ruby/gems/dry-core/lib/dry/core.rb:10:in `resolve'",
          "/usr/lib/ruby/gems/zeitwerk/lib/zeitwerk.rb:20:in `load'"
        ]
      end

      it "returns empty array" do
        expect(detector.detect_cycle).to eq([])
      end
    end

    context "with single component in backtrace" do
      let(:backtrace) do
        [
          "/app/lib/components/user_service.rb:5:in `initialize'",
          "/usr/lib/ruby/gems/dry-system/lib/dry/system/loader.rb:33:in `require!'"
        ]
      end

      it "returns empty array" do
        expect(detector.detect_cycle).to eq([])
      end
    end

    context "with two unique components" do
      let(:backtrace) do
        [
          "/app/lib/components/user_service.rb:5:in `initialize'",
          "/app/lib/components/auth_service.rb:8:in `new'",
          "/usr/lib/ruby/gems/dry-system/lib/dry/system/loader.rb:33:in `require!'"
        ]
      end

      it "returns both components as fallback cycle" do
        expect(detector.detect_cycle).to eq(%w[user_service auth_service])
      end
    end

    context "with repeated components indicating a cycle" do
      let(:backtrace) do
        [
          "/app/lib/components/foo.rb:5:in `initialize'",
          "/app/lib/components/bar.rb:8:in `new'",
          "/app/lib/components/foo.rb:5:in `initialize'",
          "/app/lib/components/bar.rb:8:in `new'",
          "/app/lib/components/foo.rb:5:in `initialize'",
          "/app/lib/components/bar.rb:8:in `new'",
          "/usr/lib/ruby/gems/dry-system/lib/dry/system/loader.rb:33:in `require!'"
        ]
      end

      it "detects the repeating cycle pattern" do
        expect(detector.detect_cycle).to eq(%w[foo bar])
      end
    end

    context "with more than 4 unique components" do
      let(:backtrace) do
        [
          "/app/lib/components/service_a.rb:5:in `initialize'",
          "/app/lib/components/service_b.rb:8:in `new'",
          "/app/lib/components/service_c.rb:3:in `initialize'",
          "/app/lib/components/service_d.rb:12:in `new'",
          "/app/lib/components/service_e.rb:7:in `initialize'",
          "/usr/lib/ruby/gems/dry-system/lib/dry/system/loader.rb:33:in `require!'"
        ]
      end

      it "returns first 4 components as fallback" do
        expect(detector.detect_cycle).to eq(%w[service_a service_b service_c service_d])
      end
    end
  end

  describe "#extract_component_files" do
    context "with valid component backtrace lines" do
      let(:backtrace) do
        [
          "/app/lib/components/user_service.rb:10:in `initialize'",
          "/app/lib/components/auth_service.rb:5:in `new'",
          "/app/other/helper.rb:15:in `initialize'"
        ]
      end

      it "extracts component file names from initialize and new methods" do
        result = subject.send(:extract_component_files)
        expect(result).to eq(%w[user_service auth_service helper])
      end
    end

    context "with system/framework files" do
      let(:backtrace) do
        [
          "/app/lib/components/user_service.rb:10:in `initialize'",
          "/usr/lib/ruby/gems/dry-system/lib/dry/system/loader.rb:33:in `require!'",
          "/usr/lib/ruby/gems/dry-core/lib/dry/core/container.rb:50:in `resolve'",
          "/app/lib/dry-custom.rb:5:in `initialize'"
        ]
      end

      it "filters out system files" do
        result = subject.send(:extract_component_files)
        expect(result).to eq(%w[user_service])
      end
    end

    context "with non-component methods" do
      let(:backtrace) do
        [
          "/app/lib/components/user_service.rb:10:in `initialize'",
          "/app/lib/components/auth_service.rb:5:in `call'",
          "/app/lib/components/data_service.rb:8:in `process'"
        ]
      end

      it "only includes initialize and new methods" do
        detector.instance_variable_set(:@backtrace, backtrace)
        result = detector.send(:extract_component_files)
        expect(result).to eq(%w[user_service])
      end
    end

    context "with malformed backtrace lines" do
      let(:backtrace) do
        [
          "/app/lib/components/user_service.rb:10:in `initialize'",
          "invalid backtrace line",
          "/app/lib/components/auth_service.rb:5:in `new'",
          "/no/method/info.rb:10"
        ]
      end

      it "handles malformed lines gracefully" do
        detector.instance_variable_set(:@backtrace, backtrace)
        result = detector.send(:extract_component_files)
        expect(result).to eq(%w[user_service auth_service])
      end
    end
  end

  describe "#system_file?" do
    it "identifies dry- prefixed files as system files" do
      expect(detector.send(:system_file?, "dry-core", "/path/dry-core.rb")).to be true
      expect(detector.send(:system_file?, "dry-system", "/path/dry-system.rb")).to be true
    end

    it "identifies loader files as system files" do
      expect(detector.send(:system_file?, "loader", "/path/loader.rb")).to be true
    end

    it "identifies component files as system files" do
      expect(detector.send(:system_file?, "component", "/path/component.rb")).to be true
    end

    it "identifies container files as system files" do
      expect(detector.send(:system_file?, "container", "/path/container.rb")).to be true
    end

    it "identifies paths with /lib/dry/ as system files" do
      expect(detector.send(:system_file?, "anything", "/app/lib/dry/system.rb")).to be true
    end

    it "identifies paths with /gems/ as system files" do
      expect(detector.send(:system_file?, "anything", "/usr/lib/ruby/gems/dry-core.rb")).to be true
    end

    it "does not identify regular user files as system files" do
      expect(detector.send(:system_file?, "user_service", "/app/lib/user_service.rb")).to be false
      expect(detector.send(:system_file?, "my_component", "/app/components/my_component.rb")).to be false
    end
  end

  describe "#component_creation_method?" do
    it "identifies initialize as component creation method" do
      expect(detector.send(:component_creation_method?, "initialize")).to be true
    end

    it "identifies new as component creation method" do
      expect(detector.send(:component_creation_method?, "new")).to be true
    end

    it "does not identify other methods as component creation methods" do
      expect(detector.send(:component_creation_method?, "call")).to be false
      expect(detector.send(:component_creation_method?, "process")).to be false
      expect(detector.send(:component_creation_method?, "execute")).to be false
    end
  end

  describe "#repeated_components?" do
    it "returns true when components repeat and there are at least 2 unique" do
      component_files = %w[foo bar foo bar]
      unique_components = %w[foo bar]

      result = detector.send(:repeated_components?, component_files, unique_components)
      expect(result).to be true
    end

    it "returns false when no repetition" do
      component_files = %w[foo bar baz]
      unique_components = %w[foo bar baz]

      result = detector.send(:repeated_components?, component_files, unique_components)
      expect(result).to be false
    end

    it "returns false when less than 2 unique components" do
      component_files = %w[foo foo foo]
      unique_components = %w[foo]

      result = detector.send(:repeated_components?, component_files, unique_components)
      expect(result).to be false
    end
  end

  describe "#find_component_cycle" do
    context "with insufficient component files" do
      it "returns empty array for less than 4 files" do
        expect(detector.send(:find_component_cycle, %w[foo bar])).to eq([])
      end
    end

    context "with repeating patterns" do
      it "detects 2-component repeating pattern" do
        component_files = %w[foo bar foo bar foo bar]
        result = detector.send(:find_component_cycle, component_files)
        expect(result).to eq(%w[foo bar])
      end

      it "detects 3-component repeating pattern" do
        component_files = %w[alpha beta gamma alpha beta gamma]
        result = detector.send(:find_component_cycle, component_files)
        expect(result).to eq(%w[alpha beta gamma])
      end

      it "returns unique components from pattern" do
        component_files = %w[foo bar bar foo bar bar] # bar appears twice in pattern
        result = detector.send(:find_component_cycle, component_files)
        expect(result).to eq(%w[foo bar]) # Deduplicated
      end
    end

    context "without clear repeating patterns" do
      it "returns empty array when no pattern found" do
        component_files = %w[foo bar baz qux]
        expect(detector.send(:find_component_cycle, component_files)).to eq([])
      end
    end
  end

  describe "#count_pattern_repetitions" do
    it "counts exact pattern repetitions" do
      component_files = %w[foo bar foo bar foo bar]
      pattern = %w[foo bar]
      pattern_length = 2

      result = detector.send(:count_pattern_repetitions, component_files, pattern, pattern_length)
      expect(result).to eq(2) # Pattern repeats 2 times before the final occurrence
    end

    it "returns 0 when pattern doesn't repeat" do
      component_files = %w[foo bar baz qux]
      pattern = %w[baz qux]
      pattern_length = 2

      result = detector.send(:count_pattern_repetitions, component_files, pattern, pattern_length)
      expect(result).to eq(0)
    end

    it "handles single element patterns" do
      component_files = %w[foo foo foo foo]
      pattern = %w[foo]
      pattern_length = 1

      result = detector.send(:count_pattern_repetitions, component_files, pattern, pattern_length)
      expect(result).to eq(3)
    end
  end

  describe "integration scenarios" do
    context "real-world backtrace simulation" do
      let(:backtrace) do
        [
          "/app/lib/services/user_service.rb:15:in `initialize'",
          "/app/lib/services/auth_service.rb:8:in `new'",
          "/usr/lib/ruby/3.3.0/gems/dry-system-1.2.3/lib/dry/system/loader.rb:47:in `call'",
          "/usr/lib/ruby/3.3.0/gems/dry-system-1.2.3/lib/dry/system/component.rb:64:in `instance'",
          "/app/lib/services/user_service.rb:15:in `initialize'",
          "/app/lib/services/auth_service.rb:8:in `new'",
          "/usr/lib/ruby/3.3.0/gems/dry-core-1.1.0/lib/dry/core/container/resolver.rb:36:in `call'",
          "/app/lib/services/user_service.rb:15:in `initialize'",
          "/app/lib/services/auth_service.rb:8:in `new'"
        ]
      end

      it "correctly identifies the cyclic dependencies" do
        expect(detector.detect_cycle).to eq(%w[user_service auth_service])
      end
    end

    context "complex cycle with multiple components" do
      let(:backtrace) do
        [
          "/app/components/service_a.rb:10:in `initialize'",
          "/app/components/service_b.rb:5:in `new'",
          "/app/components/service_c.rb:12:in `initialize'",
          "/app/components/service_a.rb:10:in `initialize'",
          "/app/components/service_b.rb:5:in `new'",
          "/app/components/service_c.rb:12:in `initialize'"
        ]
      end

      it "detects the three-component cycle" do
        expect(detector.detect_cycle).to eq(%w[service_a service_b service_c])
      end
    end
  end
end
