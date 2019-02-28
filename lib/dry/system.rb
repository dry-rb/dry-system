require 'dry-equalizer'

module Dry
  module System
    TO_SYM_ARRAY = ->(arr) { (arr.is_a?(Array) ? arr : arr.to_s.split(BOTH_SEPARATORS)).map(&:to_sym) }

    # Register external system of component providers
    #
    # @api public
    def self.register_system(system)
      systems[system.config.identifier] = system
      system.load_providers
      self
    end

    # @api private
    def self.systems
      @__systems__ ||= {}
    end

    def self.finalize!
      auto_register_systems.each do |system|
        if system.config.auto_register
          register_system(system)
        end
      end

      systems.each do |identifier, system|
        system.load_providers
      end
    end

    def self.auto_register_system(system)
      auto_register_systems << system
    end

    # @api private
    def self.auto_register_systems
      @__auto_register_systems__ ||= []
    end
  end
end

