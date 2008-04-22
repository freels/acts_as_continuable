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

    # this needs to be included in any url to reenter the method at the appropriate point.
    def context_id
      Thread.current[:context_id]
    end

    def controller
      Thread.current[:controller]
    end

    #controller emulation overrides

    def render(*args)
      instance_variables.each do |ivar|
        controller.instance_variable_set(ivar, self.instance_variable_get(ivar))
      end

      controller.send :render, *args
    end

    def method_missing(*args, &block)
      method = args.shift
      controller.send method, *args, &block
    end

    def const_missing(name)
      controller.class.const_get(name)
    end
  end
end