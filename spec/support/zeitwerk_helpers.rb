# frozen_string_literal: true

module ZeitwerkHelpers
  def teardown_zeitwerk
    # we need the double-each here because othewise we operate on a collection that
    # is directly mutated by loader.unregister, leading to unexpected results.
    # With each.to_a.each we re iterating a copy.
    Zeitwerk::Registry.loaders.each.to_a.each do |loader|
      if loader.dirs.any? { |dir| dir.include?("/spec/") || dir.include?(Dir.tmpdir) }
        loader.unregister
      end
    end
  end
end
