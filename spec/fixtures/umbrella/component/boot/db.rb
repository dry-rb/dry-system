Test::Umbrella.namespace(:db) do |container|
  module Db
    class Repo
    end
  end

  container.finalize(:db) do
    container.register(:repo, Db::Repo.new)
  end
end
