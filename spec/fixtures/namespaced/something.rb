module Tests
  module Namespaced
    class Something
      include Tests::Namespaced::Import['imported']

      def call
        imported
      end
    end
  end
end
