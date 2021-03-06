#encoding: utf-8
#########################################################################
#
# ProjEstimate, Open Source project estimation web application
# Copyright (c) 2012-2013 Spirula (http://www.spirula.fr)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################

class WbsActivity < ActiveRecord::Base

  include AASM
  include MasterDataHelper

  #attr_accessible :description, :name, :organization_id, :state, :uuid

  aasm :column => :state do # defaults to aasm_state
    state :draft, :initial => true
    state :defined
    state :retired
  end

  belongs_to :organization

  has_many :wbs_activity_elements, :dependent => :destroy
  #has_many :wbs_project_elements, :through => :wbs_activity_elements
  has_many :wbs_activity_ratios, :dependent => :destroy
  has_many :pe_wbs_projects
  has_many :pbs_project_elements

  belongs_to :record_status
  belongs_to :owner_of_change, :class_name => 'User', :foreign_key => 'owner_id'

  validates :uuid, :presence => true, :uniqueness => {:case_sensitive => false}
  validates :name, :presence => true, :uniqueness => {:scope => :record_status_id, :case_sensitive => false}
  validates :custom_value, :presence => true, :if => :is_custom?

  #Enable the amoeba gem for deep copy/clone (dup with associations)
  amoeba do
    enable
    include_field [:wbs_activity_elements, :wbs_activity_ratios]
    ###exclude_field [:pe_wbs_projects, :pbs_project_elements]      #TODO verify

    customize(lambda { |original_wbs_activity, new_wbs_activity|

      new_wbs_activity.name = "Copy_#{ original_wbs_activity.copy_number.to_i+1} of #{original_wbs_activity.name}"

      new_wbs_activity.copy_number = 0
      original_wbs_activity.copy_number = original_wbs_activity.copy_number.to_i+1
    })

    propagate
  end

end
