require 'test/relation'

module Test
  module Database
    class Users < Relation
      include Test::Container::Inject['database']
    end
  end
end
