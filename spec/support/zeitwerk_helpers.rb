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
        loader.unload
        true
      else
        false
      end
    end

    Zeitwerk::Registry.gem_loaders_by_root_file.clear
    Zeitwerk::Registry.autoloads.reject! do |path, _|
      path.include?("/spec/")
    end
    Zeitwerk::Registry.inceptions.clear

    Zeitwerk::ExplicitNamespace.cpaths.reject! do |name, _|
      name.start_with?("Dry::")
    end
  end
end
