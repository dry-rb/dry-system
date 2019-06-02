# frozen_string_literal: true

Test::Container.boot(:heaven) do
  register('heaven', 'string')
end
