class Node < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :device_type
end
