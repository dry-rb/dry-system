# frozen_string_literal: true

require "tmpdir"

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
    @load_path = $LOAD_PATH.dup
    @loaded_features = $LOADED_FEATURES.dup

    cleanable_modules.each do |mod|
      if Object.const_defined?(mod)
        Object.const_get(mod).extend(TestCleanableNamespace)
      else
        Object.const_set(mod, Module.new { |m| m.extend(TestCleanableNamespace) })
      end
    end
  end

  config.after do
    $LOAD_PATH.replace(@load_path)

    # We want to delete only newly loaded features within spec/, otherwise we're removing
    # files that may have been additionally loaded for rspec et al
    new_features_to_keep = ($LOADED_FEATURES - @loaded_features).tap do |feats|
      feats.delete_if { |path| path.include?(SPEC_ROOT.to_s) || path.include?(Dir.tmpdir) }
    end
    $LOADED_FEATURES.replace(@loaded_features + new_features_to_keep)

    cleanable_modules.each do |mod|
      next unless Object.const_defined?(mod)

      Object.const_get(mod).remove_constants
      Object.send :remove_const, mod
    end

    cleanable_constants.each do |const|
      Object.send :remove_const, const if Object.const_defined?(const)
    end
  end
end
