require 'acts_as_continuable/def_continued'
require 'acts_as_continuable/wrapper'
require 'acts_as_continuable/action'

module ActsAsContinuable
  def self.included(c)
    class << c
      include DefContinued
    end
  end
end