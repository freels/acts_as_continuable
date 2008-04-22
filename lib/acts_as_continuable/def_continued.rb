module ActsAsContinuable
  module DefContinued
    def def_continued(name, &block)
      wrapper_lambda = lambda do
        session[:contexts] ||= {}

        if from_context = session[:contexts][params[:context_id]]
          action = from_context[:action]
          entrance = from_context[:entrance]
        else
          session[:contexts] = {} # only 1 action thread per session at a time
          action = Action.new &block
          entrance = -1
        end

        context_id = rand(500000).to_s #FIXME should be unique

        # drop into the action
        action.enter(self, context_id, entrance)

        # raise if we haven't rendered yet.
        raise "render/redirect is not optional in a continued action" unless performed?

        if action.completed?
          session[:contexts].delete_if {|c_id, c| c[:action] == action }
        else
          session[:contexts][context_id] = {:action => action, :entrance => entrance + 1}
        end
      end

      define_method(name, &wrapper_lambda)    
    end
  end
end