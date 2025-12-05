# frozen_string_literal: true

module ZeitwerkLoaderRegistry
  class << self
    def new_loader
      Zeitwerk::Loader.new.tap do |loader|
        loaders << loader
      end
    end

    def clear
      loaders.each do |loader|
        loader.unregister
      end
    end

    private

    def loaders
      @loaders ||= []
    end
  end
end
