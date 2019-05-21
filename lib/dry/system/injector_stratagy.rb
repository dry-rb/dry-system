module Dry
  module System
    class InjectorStratagy < Dry::AutoInject::Strategies::Kwargs
    private

      def define_new
        # puts "HERE #{dependency_map.to_h} : #{klass}"
        super
      end

      def define_initialize(klass)
        puts "HERE #{dependency_map.to_h} : #{klass}"
        super(klass)
      end
      #
      # def define_initialize_with_keywords
      #   super
      # end
      #
      # def define_initialize_with_splat(super_method)
      #   super
      # end
    end

    Dry::AutoInject::Strategies.register :dry_system, Dry::System::InjectorStratagy
  end
end
