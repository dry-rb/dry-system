# frozen_string_literal: true

module Namespaced
  class Bar
    include Test::Container.injector['foo']
  end
end
