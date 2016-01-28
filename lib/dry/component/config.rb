require 'yaml'

module Dry
  module Component
    class Config
      def self.load(root, name, env)
        path = root.join('config').join("#{name}.yml")

        return {} unless File.exist?(path)

        yaml = YAML.load_file(path)

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
