# frozen_string_literal: true

RSpec.describe "Plugins / Dependency Graph" do
  before do
    Object.send(:remove_const, :ExternalComponents) if defined? ExternalComponents
  end
  before do
    require SPEC_ROOT.join("fixtures/external_components/lib/external_components")

    module Test
      class Container < Dry::System::Container
        use :dependency_graph

        configure do |config|
          config.ignored_dependencies = [:ignored_spec_service]
          config.root = SPEC_ROOT.join("fixtures/app").realpath
          config.component_dirs.add "lib"
        end

        boot(:mailer, from: :external_components)
        boot(:logger, from: :external_components)
      end

      Import = Container.injector
    end
  end

  subject(:container) { Test::Container }

  let(:events) { [] }
  let(:service) { Class.new { include Test::Import["logger"] }.new }

  before do
    container[:notifications].subscribe(:resolved_dependency) do |e|
      events << e
    end

    container[:notifications].subscribe(:registered_dependency) do |e|
      events << e
    end

    container.register(:service, service)
    container.finalize!
  end

  it "broadcasts dependency graph events" do
    expect(events.count).to eq(6)

    expect(events.map(&:id)).to eq(
      %i[
        resolved_dependency
        registered_dependency
        registered_dependency
        registered_dependency
        registered_dependency
        registered_dependency
      ]
    )

    expect(events.map(&:payload)).to eq([
      {dependency_map: {logger: "logger"}, target_class: service.class},
      {key: :logger, class: ExternalComponents::Logger},
      {key: :service, class: container[:service].class},
      {key: :client, class: Test::Client},
      {key: :mailer, class: ExternalComponents::Mailer},
      {key: :spec_service, class: SpecService}
    ])
  end
end
