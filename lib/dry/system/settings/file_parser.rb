# frozen_string_literal: true

module Dry
  module System
    module Settings
      class FileParser
        # Regex extracted from dotenv gem
        # https://github.com/bkeepers/dotenv/blob/master/lib/dotenv/parser.rb#L14
        LINE = %r{
          \A
          \s*
          (?:export\s+)?    # optional export
          ([\w\.]+)         # key
          (?:\s*=\s*|:\s+?) # separator
          (                 # optional value begin
            '(?:\'|[^'])*'  #   single quoted value
            |               #   or
            "(?:\"|[^"])*"  #   double quoted value
            |               #   or
            [^#\n]+         #   unquoted value
          )?                # value end
          \s*
          (?:\#.*)?         # optional comment
          \z
        }x.freeze

        def call(file)
          File.readlines(file).each_with_object({}) do |line, hash|
            parse_line(line, hash)
          end
        rescue Errno::ENOENT
          {}
        end

        private

        def parse_line(line, hash)
          if (match = line.match(LINE))
            key, value = match.captures
            hash[key] = parse_value(value || '')
          end
          hash
        end

        def parse_value(value)
          value.strip.sub(/\A(['"])(.*)\1\z/, '\2')
        end
      end
    end
  end
end
