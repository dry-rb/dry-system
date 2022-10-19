# frozen_string_literal: true

module ZeitwerkHelpers
  def teardown_zeitwerk
    # From zeitwerk's own test/support/loader_test
    # adjusted to work with dry-rb gem loaders

    Zeitwerk::Registry.loaders.reject! do |loader|
      test_loader = loader.root_dirs.any? do |dir, _|
        dir.include?("/spec/") || dir.include?(Dir.tmpdir)
      end

      if test_loader
        loader.unregister
        true
      else
        false
      end
    end
  end
end
