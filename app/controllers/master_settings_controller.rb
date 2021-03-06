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

class MasterSettingsController < ApplicationController
  include DataValidationHelper #Module for master data changes validation

  before_filter :get_record_statuses

  # GET /master_settings
  # GET /master_settings.json
  def index
    set_page_title 'Projestimate Global Parameters'
    @master_settings = MasterSetting.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @master_settings }
    end
  end

  # GET /master_settings/new
  # GET /master_settings/new.json
  def new
    set_page_title 'Projestimate Global Parameters'
    @master_setting = MasterSetting.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @master_setting }
    end
  end

  # GET /master_settings/1/edit
  def edit
    set_page_title 'Projestimate Global Parameters'
    @master_setting = MasterSetting.find(params[:id])

    unless @master_setting.child_reference.nil?
      if @master_setting.child_reference.is_proposed_or_custom?
        flash[:warning] = I18n.t (:warning_master_settings_cant_be_edit)
        redirect_to master_settings_path
      end
    end
  end

  # POST /master_settings
  # POST /master_settings.json
  def create
    @master_setting = MasterSetting.new(params[:master_setting])

    if @master_setting.save
      redirect_to redirect(master_settings_path), notice: "#{I18n.t (:notice_master_settings_successful_created)}"
    else
      render action: 'new'
    end
  end

  # PUT /master_settings/1
  # PUT /master_settings/1.json
  def update
    @master_setting = nil
    current_master_setting = MasterSetting.find(params[:id])
    if current_master_setting.is_defined?
      @master_setting = current_master_setting.amoeba_dup
      @master_setting.owner_id = current_user.id
    else
      @master_setting = current_master_setting
    end

    if @master_setting.update_attributes(params[:master_setting])
      redirect_to redirect(master_settings_path), notice: "#{I18n.t (:notice_master_settings_successful_updated)}"
    else
      render action: 'edit'
    end
  end

  # DELETE /master_settings/1
  # DELETE /master_settings/1.json
  def destroy
    @master_setting = MasterSetting.find(params[:id])
    if @master_setting.is_defined? || @master_setting.is_custom?
      #logical deletion: delete don't have to suppress records anymore
      @master_setting.update_attributes(:record_status_id => @retired_status.id, :owner_id => current_user.id)
    else
      @master_setting.destroy
    end

    respond_to do |format|
      flash[:notice] = I18n.t (:notice_master_settings_successful_deleted)
      format.html { redirect_to master_settings_url }
    end
  end
end
