# frozen_string_literal: true

require 'dry/core/constants'

module Dry
  module System
    include Dry::Core::Constants

    RB_EXT = '.rb'
    RB_GLOB = '*.rb'
    PATH_SEPARATOR = '/'
    DEFAULT_SEPARATOR = '.'
    WORD_REGEX = /\w+/.freeze
  end
end
