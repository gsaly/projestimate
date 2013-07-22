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

class WbsActivityRatiosController < ApplicationController
  include DataValidationHelper #Module for master data changes validation

  before_filter :get_record_statuses

  def export
    @wbs_activity_ratio = WbsActivityRatio.find(params[:wbs_activity_ratio_id])
    csv_string = WbsActivityRatio::export(@wbs_activity_ratio.id)
    send_data(csv_string, :type => 'text/csv; header=present', :disposition => "attachment; filename=#{@wbs_activity_ratio.name}.csv")
  end

  def import
      @wbs_activity_ratio = WbsActivityRatio.find(params[:wbs_activity_ratio_id])
    begin
      error_count = WbsActivityRatio::import(params[:file], params[:separator], params[:encoding])
    rescue
      flash[:error] = I18n.t (:error_wbs_activity_failed_import)
      redirect_to edit_wbs_activity_path(@wbs_activity_ratio.wbs_activity, :anchor => 'tabs-3') and return
    end

    ratio_elements = @wbs_activity_ratio.wbs_activity_ratio_elements
    total = ratio_elements.reject{|i| i.ratio_value.nil? or i.ratio_value.blank? }.compact.sum(&:ratio_value)

    if error_count != 0
      flash[:error] = I18n.t (:error_wbs_activity_failed_import)
    elsif total != 100
      flash[:warning] =I18n.t (:warning_import_sum_ratio_different_100)
    elsif error_count == 0 and total == 100
      flash[:notice] = I18n.t (:notice_ratio_successful_imported)
    end

    redirect_to edit_wbs_activity_path(@wbs_activity_ratio.wbs_activity, :anchor => 'tabs-3')
  end

  def edit
    set_page_title 'Edit wbs-activity ratio'
    @wbs_activity_ratio = WbsActivityRatio.find(params[:id])
    @reference_values =ReferenceValue.all.map{|i| [i.value, i.id]}
    @wbs_activity=@wbs_activity_ratio.wbs_activity
  end


  def update
    @wbs_activity_ratio = WbsActivityRatio.find(params[:id])
    @reference_values =ReferenceValue.all.map{|i| [i.value, i.id]}
    @wbs_activity=@wbs_activity_ratio.wbs_activity

    unless is_master_instance?
      if @wbs_activity_ratio.is_local_record?
        @wbs_activity_ratio.custom_value = 'Locally edited'
      end
    end

    if @wbs_activity_ratio.update_attributes(params[:wbs_activity_ratio])
      redirect_to redirect(edit_wbs_activity_path(@wbs_activity_ratio.wbs_activity, :anchor => 'tabs-3'))
    else
      render :edit
    end
  end

  def new
    set_page_title 'New wbs-activity ratio'
    @wbs_activity_ratio = WbsActivityRatio.new
    @reference_values =ReferenceValue.all.map{|i| [i.value, i.id]}
  end

  def create
    @wbs_activity_ratio = WbsActivityRatio.new(params[:wbs_activity_ratio])
    @reference_values =ReferenceValue.all.map{|i| [i.value, i.id]}
    #If we are on local instance, Status is set to "Local"
    unless is_master_instance?   #so not on master
      @wbs_activity_ratio.record_status = @local_status
    end

    if @wbs_activity_ratio.save

      @wbs_activity_ratio.wbs_activity.wbs_activity_elements.each do |wbs_activity_element|
        ware = WbsActivityRatioElement.new(:ratio_value => nil,
                                           :wbs_activity_ratio_id => @wbs_activity_ratio.id,
                                           :wbs_activity_element_id => wbs_activity_element.id,
                                           :record_status_id => @wbs_activity_ratio.record_status_id,
                                           :uuid => UUIDTools::UUID.random_create.to_s)
        ware.save(:validate => false)
      end
      redirect_to redirect_save(edit_wbs_activity_path(params[:activity_id], :anchor => 'tabs-3'), new_wbs_activity_ratio_path())
    else
      render :new
    end
  end

  def destroy
    @wbs_activity_ratio = WbsActivityRatio.find(params[:id])

    if is_master_instance?
      if @wbs_activity_ratio.is_defined? || @wbs_activity_ratio.is_custom?
        #logical deletion: delete don't have to suppress records anymore on defined record
        @wbs_activity_ratio.update_attributes(:record_status_id => @retired_status.id, :owner_id => current_user.id)
      else
        @wbs_activity_ratio.destroy
      end
    else
      if @wbs_activity_ratio.is_local_record? || @wbs_activity_ratio.is_retired?
        @wbs_activity_ratio.destroy
      else
        flash[:warning] = I18n.t (:warning_master_record_cant_be_delete)
        redirect_to redirect(groups_path)  and return
      end
    end

    flash[:notice] = I18n.t (:notice_wbs_activity_successful_deleted)
    redirect_to redirect(edit_wbs_activity_path(@wbs_activity_ratio.wbs_activity, :anchor => 'tabs-3'))
  end

  def validate_ratio
    @ratio = WbsActivityRatio.find(params[:ratio_id])
    @ratio.record_status =  @defined_status
    @ratio.transaction do
      if @ratio.save
        @ratio.wbs_activity_ratio_elements.update_all(:record_status_id => @defined_status.id)
        flash[:notice] = I18n.t (:notice_wbs_activity_ratio_successful_validated)
      else
        flash[:error] = @ratio.errors.full_messages.to_sentence
      end
    end
    redirect_to edit_wbs_activity_path(@ratio.wbs_activity, :anchor => 'tabs-3')
  end
end
