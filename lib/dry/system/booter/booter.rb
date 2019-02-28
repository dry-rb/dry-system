require 'dry/system/errors'
require 'dry/system/constants'
require 'dry/system/booter/lifecycle'

module Dry
  module System
    module Booter
      # Default booter implementation
      #
      # This is currently configured by default for every System::Container.
      # Booter objects are responsible for loading system/boot files and expose
      # an API for calling lifecycle triggers.
      #
      # @api private
      class Booter
        LOCAL_SYSTEM_KEY = :__local__

        attr_reader :booted

        attr_reader :providers

        attr_reader :container

        attr_reader :systems

        attr_reader :systems_map

        # @api private
        def initialize(container, systems = {})
          @container = container
          @booted = {}
          @systems = systems.dup
          @systems[LOCAL_SYSTEM_KEY] ||= {}
          @systems_map = Hash.new { |h, k| h[k] = {} }
        end

        def [](name)
          booted.fetch(name.to_sym)
        rescue KeyError
          raise InvalidComponentIdentifierError, name
        end

        # @api private
        def key?(name)
          booted.key?(name)
        end
        alias_method :has_key?, :key?

        def provide?(key)
          !provider_for(key).nil?
        end

        def provider_for(key)
          key = TO_SYM_ARRAY[key]

          @booted.find { |(identifier, lifecycle)| lifecycle.provide?(key) }&.first
        end

        def provided_keys
          @booted.values.map(&:provides).reduce([], :+)
        end

        def boot(identifier = nil, key: nil, from: LOCAL_SYSTEM_KEY, namespace: nil, &block)
          identifier = identifier || key
          key = key || identifier

          if key?(identifier)
            raise DuplicatedComponentKeyError, "Provider #{identifier} has already been booted."
          end

          begin
            provider = systems[from.to_sym][key.to_sym].new(
              callbacks: block,
              namespace: namespace
            )
          rescue KeyError, NoMethodError
            raise ComponentLoadError, [from, identifier]
          end

          provider.boot!(container)

          lifecycle = Lifecycle.new(identifier, provider)
          booted[identifier] = lifecycle
          systems_map[provider.system][provider.identifier] = identifier

          trigger(identifier, :boot)

          lifecycle
        end

        # @api private
        def register(provider)
          system = provider.system || LOCAL_SYSTEM_KEY
          systems[system] ||= {}

          if systems[system].key?(provider.identifier)
            raise DuplicatedComponentKeyError, "Provider #{provider.identifier} was already registered for system #{system}"
          end

          systems[system][provider.identifier] = provider

          self
        end

        # @api private
        def finalize!
          booted.keys.each do |identifier|
            start(identifier)
          end

          freeze
        end

        def start_all(identifiers, system = nil)
          identifiers.each do |identifier|
            if identifier.is_a?(Hash)
              identifier.each_pair { |pair| start_all(Array(pair[1]), pair[0].to_sym) }
            else
              if system.nil?
                start(identifier.to_sym)
              else
                if booted_identifier = systems_map[system.to_sym][identifier.to_sym]
                  start(booted_identifier)
                else
                  lifecycle = boot(identifier, from: system)
                  start(lifecycle.identifier)
                end
              end
            end
          end
        end

        # @api private
        def ensure_dependencies(identifier)
          start_all(self[identifier].provider.dependencies)
        end

        # @api private
        def shutdown
          booted.each do |identifier, lifecycle|
            stop(identifier) if lifecycle.started?
          end
        end

        def init(identifier)
          ensure_dependencies(identifier)

          trigger(identifier, :init)
        rescue Lifecycle::StateError
        end

        def start(identifier)
          init(identifier) if self[identifier].booted?

          trigger(identifier, :start)
        rescue Lifecycle::StateError
        end

        def stop(identifier)
          trigger(identifier, :stop)
        rescue Lifecycle::StateError
          raise ComponentNotStartedError, identifier
        end

        def trigger(identifier, event)
          lifecycle = self[identifier]
          lifecycle.send(event)

          merge_container(lifecycle.container, namespace: lifecycle.provider.namespace)

          self
        end

        def merge_container(lifecycle_container, namespace: nil)
          container.merge(lifecycle_container, namespace: namespace)
        end
      end
    end
  end
end
