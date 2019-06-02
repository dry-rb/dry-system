# frozen_string_literal: true

Test::Umbrella.boot(:db, namespace: 'db') do
  init do
    module Db
      class Repo
      end
    end
  end

  start do
    register(:repo, Db::Repo.new)
  end
end
