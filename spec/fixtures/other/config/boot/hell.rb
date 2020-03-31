# frozen_string_literal: true

Test::Container.boot(:heaven) do |container|
  register('heaven', 'string')
end
