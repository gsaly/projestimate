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

class PermissionsController < ApplicationController
  include DataValidationHelper #Module for master data changes validation

  before_filter :get_record_statuses

  def index
    set_page_title 'Permissions'
    @permissions = Permission.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def globals_permissions
    authorize! :manage_permissions, Permission
    set_page_title 'Globals Permissions'
    @permissions = Permission.all.select{|i| !i.is_permission_project }
    @groups = Group.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    authorize! :manage_permissions, Permission
    set_page_title 'Permissions'
    @permission = Permission.new
  end

  # GET /permissions/1/edit
  def edit
    authorize! :manage_permissions, Permission
    set_page_title 'Permissions'
    @permission = Permission.find(params[:id])

    unless @permission.child_reference.nil?
      if @permission.child_reference.is_proposed_or_custom?
        flash[:warning] = I18n.t (:warning_permission_cant_be_edit)
        redirect_to permissions_path
      end
    end
  end

  # POST /permissions
  # POST /permissions.json
  def create
    @permission = Permission.new(params[:permission])

    @groups = Group.all

    if @permission.save
      redirect_to redirect(permissions_path), notice: "#{I18n.t (:notice_permission_successful_created)}"
    else
      render action: 'new'
    end
  end

  # PUT /permissions/1
  # PUT /permissions/1.json
  def update
    @permission = nil
    current_permission = Permission.find(params[:id])
    if current_permission.is_defined?
      @permission = current_permission.amoeba_dup
      @permission.owner_id = current_user.id
    else
      @permission = current_permission
    end

    if @permission.update_attributes(params[:permission])
      redirect_to redirect('/globals_permissions'), notice: "#{I18n.t (:notice_function_successful_updated)}"
    else
      render action: 'edit'
    end
  end

  # DELETE /permissions/1
  # DELETE /permissions/1.json
  def destroy
    @permission = Permission.find(params[:id])
    if @permission.is_defined? || @permission.is_custom?
      @permission.update_attributes(:record_status_id => @retired_status.id, :owner_id => current_user.id)
    else
      @permission.destroy
    end

    respond_to do |format|
      format.html { redirect_to permissions_path, notice: "#{I18n.t (:notice_permission_successful_deleted)}" }
      format.json { head :ok }
    end
  end

  #Set all global rights
  def set_rights
    authorize! :manage_permissions, Permission
    @groups = Group.all
    @permissions = Permission.all

    @groups.each do |group|
      group.update_attribute('permission_ids', params[:permissions][group.id.to_s])
    end

    respond_to do |format|
      format.html { redirect_to '/globals_permissions', :notice => "#{I18n.t (:notice_notice_permission_successful_saved)}" }
    end

  end

  #Set all project security rights
  def set_rights_project_security
    authorize! :manage_specific_permissions, Permission
    @project_security_levels = ProjectSecurityLevel.all
    @permissions = Permission.all

    @project_security_levels.each do |psl|
      psl.update_attribute('permission_ids', params[:permissions][psl.id.to_s])
    end

    respond_to do |format|
      format.html { redirect_to project_securities_path, :notice => "#{I18n.t (:notice_notice_permission_successful_saved)}" }
    end

  end
end
