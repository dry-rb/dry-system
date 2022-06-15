# frozen_string_literal: true

module ZeitwerkHelpers
  def teardown_zeitwerk
    # From zeitwerk's own test/support/loader_test

    Zeitwerk::Registry.loaders.each(&:unload)

    Zeitwerk::Registry.loaders.clear

    # This private interface changes between 2.5.4 and 2.6.0
    if Zeitwerk::Registry.respond_to?(:loaders_managing_gems)
      Zeitwerk::Registry.loaders_managing_gems.clear
    else
      Zeitwerk::Registry.gem_loaders_by_root_file.clear
      Zeitwerk::Registry.autoloads.clear
      Zeitwerk::Registry.inceptions.clear
    end

    Zeitwerk::ExplicitNamespace.cpaths.clear
    Zeitwerk::ExplicitNamespace.tracer.disable
  end
end
