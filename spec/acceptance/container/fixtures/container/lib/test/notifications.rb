module Test
  class Notifications
    attr_reader :store

    def initialize(store)
      @store = store
    end
  end
end
