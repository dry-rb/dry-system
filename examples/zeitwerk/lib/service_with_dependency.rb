# frozen_string_literal: true

class ServiceWithDependency
  include Import["user_repo"]
end
