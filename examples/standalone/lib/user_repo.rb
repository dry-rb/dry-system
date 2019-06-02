# frozen_string_literal: true

require 'import'

class UserRepo
  include Import['persistence.db']
end
