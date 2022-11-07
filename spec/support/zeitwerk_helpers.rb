# frozen_string_literal: true

module ZeitwerkHelpers
  def teardown_zeitwerk
    ObjectSpace.each_object(Zeitwerk::Loader) do |loader|
      if loader.dirs.any? { |dir| dir.include?("/spec/") || dir.include?(Dir.tmpdir) }
        loader.unregister
      end
    end
  end
end
