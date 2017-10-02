module Dry
  module System
    RB_EXT = '.rb'.freeze
    RB_GLOB = '*.rb'.freeze
    EMPTY_STRING = ''.freeze
    PATH_SEPARATOR = '/'.freeze
    DEFAULT_SEPARATOR = '.'.freeze
    WORD_REGEX = /\w+/.freeze

    DuplicatedComponentKeyError = Class.new(ArgumentError)
  end
end
