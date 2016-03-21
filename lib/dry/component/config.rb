require 'yaml'
require 'erb'

module Dry
  module Component
    class Config
      def self.load(root, name, env)
        path = root.join('config').join("#{name}.yml")

        return {} unless File.exist?(path)

        data = ERB.new(File.read(path)).result(binding)
        yaml = YAML.load(data)

        Class.new do
          extend Dry::Configurable

          yaml.fetch(env.to_s).each do |key, value|
            setting key.downcase.to_sym, ENV.fetch(key, value)
          end
        end.config
      end
    end
  end
end
