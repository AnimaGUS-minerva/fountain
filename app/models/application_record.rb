#require 'fixture_save'

class ApplicationRecord < ActiveRecord::Base
  #include FixtureSave
  self.abstract_class = true

end
