require 'import'

class ServiceWithDependency
  include Import['user_repo']
end
