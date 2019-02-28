module Test
  module Bacon
    class InMemoryStore
      def initialize
        @state = nil
      end

      [:inited, :started, :stopped].each do |meth|
        define_method("#{meth}?") { @state == meth }
      end

      def init!
        @state = :inited
      end

      def start!
        @state = :started
      end

      def stop!
        @state = :stopped
      end
    end
  end
end
