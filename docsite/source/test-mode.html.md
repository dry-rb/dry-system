---
title: Test Mode
layout: gem-single
name: dry-system
---

In some cases it is useful to stub a component in your tests. To enable this, dry-system provides a test mode,
in which a container will not be frozen during finalization. This allows you to use `stub` API to stub a given component.

``` ruby
require 'dry/system'

class Application < Dry::System::Container
  configure do |config|
    config.root = Pathname('./my/app')
  end
end

require 'dry/system/stubs'

Application.enable_stubs!

Application.stub('persistence.db', stubbed_db)
```

Typically, you want to use `enable_stubs!` in a test helper file, before booting your system.
