require 'logger'

Test::Container.boot(:logger) do |app|
  init do
    log_path = app.config.root.join('log/test.log').to_s
    register(:logger, ::Logger.new(log_path))
  end
end
