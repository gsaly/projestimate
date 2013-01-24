class WbsActivityElementsController < ApplicationController
  include PeWbsHelper
  include DataValidationHelper #Module for master data changes validation

  before_filter :get_record_statuses

  def index
    set_page_title "WBS-Activity elements"
    @wbs_activity_elements = WbsActivityElement.all
  end

  def show
    set_page_title "WBS-Activity elements"
    @wbs_activity_element = WbsActivityElement.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @wbs_activity_element }
    end
  end

  def new
    set_page_title "WBS-Activity elements"
    @wbs_activity_element = WbsActivityElement.new
  end

  def edit
    set_page_title "WBS-Activity elements"
    @wbs_activity_element = WbsActivityElement.find(params[:id])

    if is_master_instance?

      unless @wbs_activity_element.child_reference.nil?
        if @wbs_activity_element.child_reference.is_proposed_or_custom?
          flash[:notice] = "This Wbs-Activity element can't be edited, previous changes have not yet been validated."
          redirect_to wbs_activity_elements_url and return
        end
      end
    else
      if @wbs_activity_element.is_local_record?
        @wbs_activity_element.record_status = @local_status
      else
        flash[:error] = "Master record can not be deleted, it is required for the proper functioning of the application"
        redirect_to wbs_activity_elements_url
      end
    end
  end

  def create
    @wbs_activity_element = WbsActivityElement.new(params[:wbs_activity_element])

    #If we are on local instance, Status is set to "Local"
    if is_master_instance?   #so not on master
      @wbs_activity_element.record_status = @proposed_status
    else
      @wbs_activity_element.record_status = @local_status
    end

    if @wbs_activity_element.save
      redirect_to wbs_activity_elements_path, notice: 'Wbs activity element was successfully created.'
    else
       render action: "new"
    end
  end

  def update
    @wbs_activity_element = nil
    current_wbs_activity_element = WbsActivityElement.find(params[:id])

    if current_wbs_activity_element.is_defined?
      @wbs_activity_element = current_wbs_activity_element.amoeba_dup
      @wbs_activity_element.owner_id = current_user.id
    else
      @wbs_activity_element = current_wbs_activity_element
    end

    unless is_master_instance?
      if @wbs_activity_element.is_local_record?
        @wbs_activity_element.custom_value = "Locally edited"
      end
    end

    if @wbs_activity_element.update_attributes(params[:wbs_activity_element])
      redirect_to wbs_activity_elements_path, notice: 'Wbs activity element was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @wbs_activity_element = WbsActivityElement.find(params[:id])

    #@wbs_activity_element.destroy
    if is_master_instance?
      if @wbs_activity_element.is_defined? || @wbs_activity_element.is_custom?
        #logical deletion  delete don't have to suppress records anymore on Defined record
        @wbs_activity_element.update_attributes(:record_status_id => @retired_status.id, :owner_id => current_user.id)
      else
        @wbs_activity_element.destroy
      end
    else
      if @wbs_activity_element.is_local_record?
        @wbs_activity_element.destroy
      else
        flash[:error] = "Master record can not be deleted, it is required for the proper functioning of the application"
        redirect_to redirect(wbs_activity_elements_path)  and return
      end
    end

    respond_to do |format|
      format.html { redirect_to wbs_activity_elements_url }
      format.json { head :no_content }
    end
  end

end