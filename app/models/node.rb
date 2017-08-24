class Node < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :device_type

  def self.find_or_make_by_number(idevid)
    where(idevid: idevid).take || create(idevid: idevid)
  end
end
