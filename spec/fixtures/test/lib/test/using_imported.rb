module Test
  class UsingImported
    include Import['other.test.importable_dep']
  end
end
