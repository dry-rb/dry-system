# frozen_string_literal: true

require "dry/core/deprecations"

module Dry
  module System
    class Provider
      # Configures a Dry::System::Provider::Source subclass using a DSL that makes it
      # nicer to define source behaviour via a single block.
      #
      # @see Dry::System::Container.register_provider
      #
      # @api private
      class SourceDSL
        extend Dry::Core::Deprecations["Dry::System::Provider::SourceDSL"]

        def self.evaluate(source_class, target_container, &block)
          if block.parameters.any?
            Dry::Core::Deprecations.announce(
              "Dry::System.register_provider with single block parameter",
              "Use `target_container` (or `target` for short) inside your block instead",
              tag: "dry-system"
            )
            new(source_class).instance_exec(target_container, &block)
          else
            new(source_class).instance_eval(&block)
          end
        end

        attr_reader :source_class

        def initialize(source_class)
          @source_class = source_class
        end

        def setting(*args, **kwargs, &block)
          source_class.setting(*args, **kwargs, &block)
        end

        # rubocop:disable Layout/LineLength

        def settings(&block)
          Dry::Core::Deprecations.announce(
            "Dry::System.register_provider with nested settings block",
            "Use individual top-level `setting` declarations instead (see dry-configurable docs for details)",
            tag: "dry-system",
            uplevel: 1
          )

          DeprecatedSettingsDSL.new(self).instance_eval(&block)
        end

        # rubocop:enable Layout/LineLength

        class DeprecatedSettingsDSL
          def initialize(base_dsl)
            @base_dsl = base_dsl
          end

          def key(name, type)
            @base_dsl.setting(name, constructor: type)
          end
        end

        def prepare(&block)
          source_class.define_method(:prepare, &block)
        end
        deprecate :init, :prepare

        def start(&block)
          source_class.define_method(:start, &block)
        end

        def stop(&block)
          source_class.define_method(:stop, &block)
        end

        private

        def method_missing(name, *args, &block)
          if source_class.respond_to?(name)
            source_class.public_send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, include_all = false)
          source_class.respond_to?(name, include_all) || super
        end
      end
    end
  end
end
