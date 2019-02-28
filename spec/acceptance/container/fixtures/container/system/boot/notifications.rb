require 'test/notifications'

Test::Container.boot(:notifications) do |app|
  use bacon: :in_memory

  start do
    register(:notifications, Test::Notifications.new(app[:in_memory]))
  end
end
