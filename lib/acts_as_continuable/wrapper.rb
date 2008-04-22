module ActsAsContinuable
  class Wrapper
    DeferredMethods = %w( render redirect_to )
    
    def initialize(&block) #:nodoc:
      (class << self; self; end).send(:define_method, :the_action, &block)
    end

    protected

    # Pauses the action methods's flow of execution and passes to the current
    # ActionController.
    def continue
      Thread.stop #wait for reentry from ActsAsContinuable#enter

      # if we are reentering a previous point, :entrance will be non-nil
      Thread.current[:entrance].call unless Thread.current[:entrance].nil?
      callcc {|cc| Thread.current[:next_entrance] = cc }
    end

    # Returns the running instance of ActionController.
    # *Note*: This instance is different each request/response cycle, so don't
    # keep a reference to it.
    def controller
      Thread.current[:controller]
    end

    # Overrides ActionController's +render+ so that <tt>@context_id</tt> is
    # available for your views to add to links back into the action flow.
    # The actual render is deferred until after the action thread has been
    # paused and stored.
    # 
    # Currently, +render+ is not called implicitly after an action has continued
    # or completed. If you do not render or redirect, an exception will be
    # raised.
    def render(*args)
      controller.instance_variable_set(:@context_id, Thread.current[:context_id])
      
      instance_variables.each do |ivar|
        controller.instance_variable_set(ivar, self.instance_variable_get(ivar))
      end

      call_or_defer(:render, *args)
    end
        
    # Methods called in your action get passed to the current request's
    # ActionController instance. Certain actions have trouble excecuting
    # within the container thread, such as render. Instead of being excecuted
    # immediately, these are stored and called in the main thread of execution
    # after the action thread has been paused and stored. (After +continue+)
    def call_or_defer(*args, &block)
      method = args.shift
      
      if DeferredMethods.include? method
        Thread.current[:deferred_methods] << [method, args, block]
      else
        controller.send method, *args, &block
      end
    end
    
    alias method_missing call_or_defer #:nodoc:

    def const_missing(name) #:nodoc:
      controller.class.const_get(name)
    end
  end
end
