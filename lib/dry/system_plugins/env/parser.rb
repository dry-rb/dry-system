module Dry
  module SystemPlugins
    module Env
      class Parser
        LINE = %r(
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
        )x

        PARSE_VALUE = ->(value) { value.strip.sub(/\A(['"])(.*)\1\z/, '\2') }

        def self.[](file)
          call(file)
        end

        def self.call(file)
          captures = file.split("\n")
            .map(&LINE.method(:match))
            .compact
            .map(&:captures)

          captures.each_with_object({}) do |(key, value), h|
            h[key] = PARSE_VALUE[value]
          end
        end
      end
    end
  end
end
