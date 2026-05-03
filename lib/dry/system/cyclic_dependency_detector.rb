# frozen_string_literal: true

module Dry
  module System
    # Detects cyclic dependencies from SystemStackError backtraces
    #
    # @api private
    class CyclicDependencyDetector
      # Detects cyclic dependencies from SystemStackError backtrace
      #
      # @param backtrace [Array<String>] The backtrace from SystemStackError
      # @return [Array<String>] Array of component names forming the cycle
      #
      # @api private
      def self.detect_from_backtrace(backtrace)
        new(backtrace).detect_cycle
      end

      # @api private
      def initialize(backtrace)
        @backtrace = backtrace
      end

      # @api private
      def detect_cycle
        component_files = extract_component_files
        unique_components = component_files.uniq

        # If we have repeated component names, we likely have a cycle
        if repeated_components?(component_files, unique_components)
          cycle = find_component_cycle(component_files)
          return cycle if cycle.any?
        end

        # Fallback: if we have multiple unique components in the stack, assume
        # they form a cycle
        return unique_components.first(4) if unique_components.length >= 2

        []
      end

      private

      attr_reader :backtrace

      def extract_component_files
        component_files = []

        backtrace.each do |frame|
          # Extract component information: file name and method name
          _, file_name, method_name = frame.match(%r{/([^/]+)\.rb:\d+:in\s+`([^']+)'}).to_a
          next unless file_name && method_name

          # Skip system/framework files
          next if system_file?(file_name, frame)

          # Focus on initialize methods which are likely where dependency cycles occur
          component_files << file_name if component_creation_method?(method_name)
        end

        component_files
      end

      def system_file?(file_name, frame)
        file_name.start_with?("dry-", "loader", "component", "container") ||
          frame.include?("/lib/dry/") ||
          frame.include?("/gems/")
      end

      def component_creation_method?(method_name)
        method_name == "initialize" || method_name == "new"
      end

      def repeated_components?(component_files, unique_components)
        component_files.length > unique_components.length && unique_components.length >= 2
      end

      def find_component_cycle(component_files)
        return [] if component_files.length < 4

        # Look for patterns where the same component sequence repeats
        (2..component_files.length / 2).each do |pattern_length|
          pattern = component_files[-pattern_length..]
          repeat_count = count_pattern_repetitions(component_files, pattern, pattern_length)

          # If we found at least 2 repetitions, this is likely a cycle
          return pattern.uniq if repeat_count >= 1
        end

        []
      end

      def count_pattern_repetitions(component_files, pattern, pattern_length)
        repeat_count = 0
        start_pos = component_files.length - pattern_length

        while start_pos >= pattern_length
          if component_files[start_pos - pattern_length, pattern_length] == pattern
            repeat_count += 1
            start_pos -= pattern_length
          else
            break
          end
        end

        repeat_count
      end
    end
  end
end
