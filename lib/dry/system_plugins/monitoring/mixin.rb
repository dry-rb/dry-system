module Dry
  module SystemPlugins
    module Monitoring
      module Mixin
        # @api private
        def monitor(key, options = {}, &block)
          notifications = self[:notifications]

          resolve(key).tap do |target|
            proxy = Proxy.for(target, options.merge(key: key))

            if block
              proxy.monitored_methods.each do |meth|
                notifications.subscribe(:monitoring, target: key, method: meth, &block)
              end
            end

            decorate(key, with: proxy.new(target, notifications))
          end
        end
      end
    end
  end
end
