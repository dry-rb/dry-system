require 'import'

module Entities
  class User
    include Import['persistence.db']
  end
end
