module ZeitwerkHelpers
  def teardown_zeitwerk
    # From zeitwerk's own test/support/loader_test

    Zeitwerk::Registry.loaders.each(&:unload)

    Zeitwerk::Registry.loaders.clear
    Zeitwerk::Registry.loaders_managing_gems.clear

    Zeitwerk::ExplicitNamespace.cpaths.clear
    Zeitwerk::ExplicitNamespace.tracer.disable
  end
end