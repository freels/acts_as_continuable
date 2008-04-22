module ActsAsContinuable
  class Action
    Thread.abort_on_exception = true

    @@all_threads ||= []
    @@all_threads_mutex ||= Mutex.new

    def initialize(&block)
      @wrapper = Wrapper.new(&block)
      @entrances = []

      @thread = Thread.new do
        Thread.stop #wait for reentry from ActsAsContinuable#enter
        @wrapper.the_action
      end

      @@all_threads_mutex.synchronize { @@all_threads << @thread }

      Thread.pass until self.thread.stop?
    end

    def completed?
      self.thread.nil?
    end

    # entrance_idx is the index of the entrance point we want to continue from, with 0 being
    # the first continuation in the action and @entrances.length the natural flow of the action. (i.e.: we
    # just unpause the thread rather than call a continuation)
    def enter(controller, context_id, entrance_idx)      
      raise "Thread is dead!" if self.completed? || !thread.alive?

      thread[:controller] = controller
      thread[:entrance] = @entrances[entrance_idx] if entrance_idx < @entrances.length && entrance_idx > -1
      thread[:context_id] = context_id
      thread[:deferred_methods] = []

      thread.run                     # reenter thread at Wrapper#continue
      Thread.pass until thread.stop? # wait for thread
      
      thread[:deferred_methods].each do |m_array|
        controller.send(m_array[0], *m_array[1], &m_array[2])
      end
      thread[:deferred_methods] = nil

      if thread.alive?
        # kill all entrances to our alternate future
        @entrances = @entrances[0, entrance_idx + 1]

        @entrances << thread[:next_entrance] unless thread[:next_entrance].nil?  

        thread[:entrance] = thread[:next_entrance] = nil
      else
        cleanup
      end
    end

    protected

    attr_reader :thread

    def cleanup
      @thread = nil
      @entrances = []
      self.freeze
    end  
  end
end
