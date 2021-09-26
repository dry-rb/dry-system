# frozen_string_literal: true

module TestCleanableNamespace
  def remove_constants
    constants.each do |name|
      remove_const(name)
    end
  end
end

RSpec.shared_context "Loaded constants cleaning" do
  let(:cleanable_modules) { %i[Test] }
  let(:cleanable_constants) { [] }
end

RSpec.configure do |config|
  config.include_context "Loaded constants cleaning"

  config.before do
    @load_paths = $LOAD_PATH.dup
    @loaded_features = $LOADED_FEATURES.dup

    cleanable_modules.each do |mod|
      Object.const_set(mod, Module.new { |m| m.extend(TestCleanableNamespace) })
    end
  end

  config.after do
    $LOAD_PATH.replace(@load_paths)
    $LOADED_FEATURES.replace(@loaded_features)

    cleanable_modules.each do |mod|
      Object.const_get(mod).remove_constants
      Object.send :remove_const, mod
    end

    cleanable_constants.each do |const|
      Object.send :remove_const, const
    end
  end
end
