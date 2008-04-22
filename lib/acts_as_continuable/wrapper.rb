module ActsAsContinuable
  class Wrapper
    def initialize(&block)
      (class << self; self; end).send(:define_method, :the_action, &block)
    end

    protected

    def continue      
      Thread.stop #wait for reentry from ActsAsContinuable#enter

      # if we are reentering a previous point, :entrance will be non-nil
      Thread.current[:entrance].call unless Thread.current[:entrance].nil?
      callcc {|cc| Thread.current[:next_entrance] = cc }
    end

    def controller
      Thread.current[:controller]
    end

    #controller emulation overrides

    def render(*args)
      controller.instance_variable_set(:@context_id, Thread.current[:context_id])
      
      instance_variables.each do |ivar|
        controller.instance_variable_set(ivar, self.instance_variable_get(ivar))
      end

      call_or_defer(:render, *args)
    end
    
    DeferredMethods = %w[ render redirect_to ]
    
    def call_or_defer(*args, &block)
      method = args.shift
      
      if DeferredMethods.include? method
        Thread.current[:deferred_methods] << [method, args, block]
      else
        controller.send method, *args, &block
      end
    end
    alias method_missing call_or_defer

    def const_missing(name)
      controller.class.const_get(name)
    end
  end
end
