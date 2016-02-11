require 'dry/component/namespace'

RSpec.describe Dry::Component::Namespace do
  subject! { Tests::Namespaced }

  before(:all) do
    require SPEC_ROOT.join("fixtures/namespaced/namespace")
    Tests::Namespaced.finalize!
  end

  it 'defines a container inside the namespace' do
    expect(Tests::Namespaced::Container).to be_kind_of(Dry::Container::Mixin)
  end

  it 'auto_register inside the namespace' do
    expect(subject['foos.bar']).to be_kind_of(Tests::Namespaced::Foos::Bar)
  end

  it 'works with auto inject' do
    expect(Tests::Namespaced::Something.new.call).to be_kind_of(Tests::Namespaced::Imported)
  end
end
