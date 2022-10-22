# frozen_string_literal: true

module ZeitwerkHelpers
  def teardown_zeitwerk
    # From zeitwerk's own test/support/loader_test
    # adjusted to work with dry-rb gem loaders

    Zeitwerk::Registry.loaders.reject! do |loader|
      test_loader = loader.dirs.any? { |dir| dir.include?("/spec/") || dir.include?(Dir.tmpdir) }

      if test_loader
        loader.unregister
        true
      else
        false
      end
    end
  end
end
