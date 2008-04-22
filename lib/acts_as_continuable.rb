require 'acts_as_continuable/def_continued'
require 'acts_as_continuable/wrapper'
require 'acts_as_continuable/action'

# :include: README.rdoc

module ActsAsContinuable
  def self.included(c) #:nodoc:
    raise "Session store must be in memory for ActsAsContinuable" unless ActionController::Base.session_store == CGI::Session::MemoryStore
    class << c
      include DefContinued
    end
  end
end
