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

class RecordStatusesController < ApplicationController
  include DataValidationHelper #Module for master data changes validation

  before_filter :get_record_statuses

  # GET /record_statuses
  # GET /record_statuses.json
  def index
    @record_statuses = RecordStatus.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @record_statuses }
    end
  end

  # GET /record_statuses/1
  # GET /record_statuses/1.json
  def show
    @record_status = RecordStatus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @record_status }
    end
  end

  # GET /record_statuses/new
  # GET /record_statuses/new.json
  def new
    @record_status = RecordStatus.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @record_status }
    end
  end

  # GET /record_statuses/1/edit
  def edit
    @record_status = RecordStatus.find(params[:id])

    unless @record_status.child_reference.nil?
      if @record_status.child_reference.is_proposed_or_custom?
        flash[:warning] = I18n.t(:warning_record_status_cant_be_edit)
        redirect_to record_statuses_path
      end
    end
  end

  # POST /record_statuses
  # POST /record_statuses.json
  def create
    @record_status = RecordStatus.new(params[:record_status])

    respond_to do |format|
      if @record_status.save
        format.html { redirect_to record_statuses_path, notice: "#{I18n.t(:notice_record_status_successful_created)}" }
        format.json { render json: @record_status, status: :created, location: @record_status }
      else
        format.html { render action: 'new' }
        format.json { render json: @record_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /record_statuses/1
  # PUT /record_statuses/1.json
  def update
    @record_status = nil
    current_record_status = RecordStatus.find(params[:id])
    if current_record_status.is_defined?
      @record_status = current_record_status.amoeba_dup
      @record_status.owner_id = current_user.id
    else
      @record_status = current_record_status
    end

    respond_to do |format|
      if @record_status.update_attributes(params[:record_status])
        format.html { redirect_to record_statuses_path, notice: "#{I18n.t (:notice_record_status_successful_updated)}" }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @record_status.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /record_statuses/1
  # DELETE /record_statuses/1.json
  def destroy
    @record_status = RecordStatus.find(params[:id])
    if @record_status.is_defined? || @record_status.is_custom?
      #logical deletion: delete don't have to suppress records anymore
      @record_status.update_attributes(:record_status_id => @retired_status.id, :owner_id => current_user.id)
    else
      @record_status.destroy
    end

    respond_to do |format|
      format.html { redirect_to record_statuses_url }
      format.json { head :no_content }
    end
  end
end
