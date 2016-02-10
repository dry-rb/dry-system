require 'dry/component/namespace'
require SPEC_ROOT.join("fixtures/namespaced/namespace")

RSpec.describe Dry::Component::Namespace do
  subject! { Tests::Namespaced }

  before(:all) do
    Tests::Namespaced.finalize!
  end

  it 'defines a container inside the namespace' do
    expect(Tests::Namespaced::Container).to be_kind_of(Dry::Container::Mixin)
  end

  it 'auto_register inside the namespace' do
    expect(subject['foos.bar']).to be_kind_of(Tests::Namespaced::Foos::Bar)
  end
end
