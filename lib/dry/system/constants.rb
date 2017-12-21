require 'dry/core/constants'

module Dry
  module System
    include Dry::Core::Constants

    RB_EXT = '.rb'.freeze
    RB_GLOB = '*.rb'.freeze
    PATH_SEPARATOR = '/'.freeze
    DEFAULT_SEPARATOR = '.'.freeze
    WORD_REGEX = /\w+/.freeze

    DuplicatedComponentKeyError = Class.new(ArgumentError)
  end
end
