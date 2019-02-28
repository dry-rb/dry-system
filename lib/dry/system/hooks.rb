module Dry
  module System
    class Hooks
      attr_reader :events, :subscribers

      def initialize
        @events = Hash.new { |h, k| h[k] = {before: [], after: []}}
        @subscribers = []
      end

      def before(event, &block)
        @events[event.to_sym][:before] << block
      end

      def after(event, &block)
        @events[event.to_sym][:after] << block
      end

      def subscribe(obj)
        @subscribers << obj
      end

      def trigger(event, phase = nil)
        event = event.to_s.gsub('!', '').to_sym
        phases = phase ? [phase] : [:before, nil, :after]

        phases.each do |phase|
          @subscribers.each do |subscriber|
            meth = phase ? "trigger_#{phase}_#{event}" : "trigger_#{event}"

            if subscriber.respond_to?(meth)
              subscriber.send(meth)
            else
              subscriber.trigger(event, phase)
            end
          end

          if @events.key?(event) && @events[event].key?(phase)
            @events[event][phase || :on].each(&:call)
          end
        end
      end
    end
  end
end