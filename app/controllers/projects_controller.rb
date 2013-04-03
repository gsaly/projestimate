#encoding: utf-8
#########################################################################
#
# ProjEstimate, Open Source project estimation web application
# Copyright (c) 2012 Spirula (http://www.spirula.fr)
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
class ProjectsController < ApplicationController
  include WbsActivityElementsHelper

  helper_method :sort_column
  helper_method :sort_direction

  before_filter :load_data, :only => [:update, :edit, :new, :create]
  before_filter :get_record_statuses

  def load_data
    if params[:id]
      @project = Project.find(params[:id])
    else
      @project = Project.new :state => "preliminary"
    end
    @user = @project.users.first
    @project_areas = ProjectArea.all
    @platform_categories = PlatformCategory.all
    @acquisition_categories = AcquisitionCategory.all
    @project_categories = ProjectCategory.all
    @pemodules ||= Pemodule.all
    @project_modules = @project.pemodules
    @module_positions = ModuleProject.where(:project_id => @project.id).order(:position_y).all.map(&:position_y).uniq.max || 1
    @organizations = Organization.all
    @project_modules = @project.pemodules
    @project_security_levels = ProjectSecurityLevel.all
    @module_project = ModuleProject.find_by_project_id(@project.id)
  end

  def index
    set_page_title "Projects"
    @projects = Project.page(params[:page]).per_page(5)
    respond_to do |format|
      format.html
      format.js {
        render :partial => "project_record_number"
      }
    end
  end

  def new
    set_page_title "New project"
  end

  #Create a new project
  def create
    set_page_title "Create project"
    @project = Project.new(params[:project])
    @wbs_activity_elements = []

    begin
      @project.transaction do
        if @project.save
          #New default Pe-Wbs-Project
          pe_wbs_project_product  = @project.pe_wbs_projects.build(:name => "#{@project.title} WBS-Product - Product Breakdown Structure", :wbs_type => "Product")
          pe_wbs_project_activity = @project.pe_wbs_projects.build(:name => "#{@project.title} WBS-Activity - Activity breakdown Structure", :wbs_type => "Activity")

          if pe_wbs_project_product.save
            ##New root Pbs-Project-Element
            pbs_project_element = pe_wbs_project_product.pbs_project_elements.build(:name => "Root Element - #{@project.title} WBS-Product", :is_root => true, :work_element_type_id => default_work_element_type.id, :position => 0)
            pbs_project_element.save
            pe_wbs_project_product.save
          end

          if pe_wbs_project_activity.save
            ##New Root Wbs-Project-Element
            wbs_project_element = pe_wbs_project_activity.wbs_project_elements.build(:name => "Root Element - #{@project.title} WBS-Activity", :is_root => true, :description => "WBS-Activity Root Element", :author_id => current_user.id)
            wbs_project_element.save
          end

          if current_user.groups.map(&:code_group).include? ("super_admin")
            current_user.project_ids = current_user.project_ids.push(@project.id)
            current_user.save
          end

          redirect_to redirect(edit_project_path(@project)), notice: "#{I18n.t (:project_succesfull_created)}"
        else
          flash[:error] = I18n.t (:project_creation_failled)+" "+ @project.errors.full_messages.to_sentence + "."
          render :new
        end
      end

    rescue ActiveRecord::UnknownAttributeError, ActiveRecord::StatementInvalid, ActiveRecord::RecordInvalid => error
      flash[:error] = I18n.t (:project_creation_failled) + " " +@project.errors.full_messages.to_sentence + "."
      redirect_to :back
    end

  end

  #Edit a selected project
  def edit
    authorize! :modify_a_project, Project
    set_page_title "Edit project"

    @project = Project.find(params[:id])
    @pe_wbs_project_product = @project.pe_wbs_projects.wbs_product.first
    @pe_wbs_project_activity = @project.pe_wbs_projects.wbs_activity.first
    @wbs_activity_ratios = []

    defined_wbs_activities = WbsActivity.where('record_status_id = ?', @defined_status.id).all
    @wbs_activities = defined_wbs_activities.reject {|i| @project.included_wbs_activities.include?(i.id) }
    @wbs_activity_elements = []
    @wbs_activities.each do |wbs_activity|
      elements_root = wbs_activity.wbs_activity_elements.elements_root.first
      unless elements_root.nil?
        @wbs_activity_elements << elements_root  #wbs_activity.wbs_activity_elements.last.root
      end
    end
  end

  def update
    set_page_title "Edit project"

    @pe_wbs_project_product = @project.pe_wbs_projects.wbs_product.first
    @pe_wbs_project_activity = @project.pe_wbs_projects.wbs_activity.first
    @wbs_activity_elements = []

    @project.users.each do |u|
      ps = ProjectSecurity.find_by_user_id_and_project_id(u.id, @project.id)
      if ps
        ps.project_security_level_id = params["user_securities_#{u.id}"]
        ps.save
      else
        ProjectSecurity.create(:user_id => u.id,
                               :project_id => @project.id,
                               :project_security_level_id => params["user_securities_#{u.id}"])
      end
    end

    @project.groups.each do |gpe|
      ps = ProjectSecurity.find_by_group_id_and_project_id(gpe.id, @project.id)
      if ps
        ps.project_security_level_id = params["group_securities_#{gpe.id}"]
        ps.save
      else
        ProjectSecurity.create(:group_id => gpe.id,
                               :project_id => @project.id,
                               :project_security_level_id => params["group_securities_#{gpe.id}"])
      end
    end

    if @project.update_attributes(params[:project])
      redirect_to redirect(projects_url), notice: "#{I18n.t (:project_succesfull_updated)}"
    else
      render(:edit)
    end
  end
  
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    current_user.delete_recent_project(@project.id)
    session[:current_project_id] = current_user.projects.first

    redirect_to session[:return_to]
  end

  def select_categories
    if params[:project_area_selected].is_numeric?
      @project_area = ProjectArea.find(params[:project_area_selected])
    else
      @project_area = ProjectArea.find_by_name(params[:project_area_selected])
    end

    @project_areas = ProjectArea.all
    @platform_categories = PlatformCategory.all
    @acquisition_categories = AcquisitionCategory.all
    @project_categories = ProjectCategory.all
  end

  #Change selected project ("Jump to a project" select box)
  def change_selected_project
    if params[:project_id]
      session[:current_project_id] = params[:project_id]
    end
    redirect_to "/dashboard"
  end

  #Load specific security depending of user selected (last tabs on project editing page)
  def load_security_for_selected_user
    @user = User.find(params[:user_id])
    @project = Project.find(params[:project_id])
    @prj_scrt = ProjectSecurity.find_by_user_id_and_project_id(@user.id, @project.id)
    if @prj_scrt.nil?
      @prj_scrt = ProjectSecurity.create(:user_id => @user.id, :project_id =>  @project.id)
    end

    respond_to do |format|
      format.js { render :partial => "projects/run_estimation" }
    end

  end

  #Load specific security depending of user selected (last tabs on project editing page)
  def load_security_for_selected_group
    @group = Group.find(params[:group_id])
    @project = Project.find(params[:project_id])
    @prj_scrt = ProjectSecurity.find_by_group_id_and_project_id(@group.id, @project.id)
    if @prj_scrt.nil?
      @prj_scrt = ProjectSecurity.create(:group_id => @user.id, :project_id =>  @project.id)
    end

    respond_to do |format|
      format.js { render :partial => "projects/run_estimation" }
    end

  end

  #Updates the security according to the previous users
  def update_project_security_level
    @user = User.find(params[:user_id].to_i)
    @prj_scrt = ProjectSecurity.find_by_user_id_and_project_id(@user.id, current_project.id)
    @prj_scrt.update_attribute("project_security_level_id", params[:project_security_level])

    respond_to do |format|
      format.js { render :partial => "projects/run_estimation" }
    end

  end

    #Updates the security according to the previous users
  def update_project_security_level_group
    @group = Group.find(params[:group_id].to_i)
    @prj_scrt = ProjectSecurity.find_by_group_id_and_project_id(@group.id, current_project.id)
    @prj_scrt.update_attribute("project_security_level_id", params[:project_security_level])

    respond_to do |format|
      format.js { render :partial => "projects/run_estimation" }
    end

  end

  #Allow o add a module to a estimation process
  def add_module
    @array_modules = Pemodule.all
    @project = Project.find(params[:project_id])
    @pemodules ||= Pemodule.all

    #Max pos or 1
    @module_positions = ModuleProject.where(:project_id => @project.id).order(:position_y).all.map(&:position_y).uniq.max || 1

    #When adding a module in the "timeline", it creates an entry in the table ModuleProject for the current project, at position 2 (the one being reserved for the input module).
    my_module_project = ModuleProject.new(:project_id => @project.id, :pemodule_id => params[:module_selected], :position_y => 1, :position_x => 1)
    my_module_project.save

    #For each attribute of this new ModuleProject, it copy in the table ModuleAttributeProject, the attributes of modules.
    @project.pe_wbs_projects.wbs_product.first.pbs_project_elements.each do |c|

      my_module_project.pemodule.attribute_modules.each do |am|
        mpa = EstimationValue.create(  :attribute_id => am.attribute.id,
                                              :module_project_id => my_module_project.id,
                                              :in_out => am.in_out,
                                              :is_mandatory => am.is_mandatory,
                                              :description => am.description,
                                              :numeric_data_low => am.numeric_data_low,
                                              :numeric_data_most_likely => am.numeric_data_most_likely,
                                              :numeric_data_high => am.numeric_data_high,
                                              :custom_attribute => am.custom_attribute,
                                              :pbs_project_element_id => c.id,
                                              :dimensions => am.dimensions,
                                              :project_value => am.project_value )
      end
    end
  end

  def select_pbs_project_elements
    @project = Project.find(params[:project_id])
    if params[:pbs_project_element_id]
      @pbs_project_element = PbsProjectElement.find(params[:pbs_project_element_id])
    else
      @pbs_project_element = @project.root_component
    end
    @module_positions = ModuleProject.where(:project_id => @project.id).order(:position_y).all.map(&:position_y).uniq.max || 1
  end

  #Run estimation process
  def run_estimation
    @resultat = Array.new

    #@project = current_project
    #@pbs_project_element = current_component
    #@folders = @project.folders.reverse
    #val = 0
    #@array_module_positions = ModuleProject.where(:project_id => @project.id).sort_by{|i| i.position_y}.map(&:position_y).uniq.max || 1

    ##For each level...
    #["low", "most_likely", "high"].each do |level|
    #
    #  @project.module_projects.each do |mp|
    #    mp.estimation_values.reject{|i| i.pbs_project_element_id != current_component.id}.each do |mpa|
    #
    #      if mpa.input?
    #
    #        unless input_value[mp.pemodule.alias.to_sym].nil?
    #          val = input_value[mp.pemodule.alias.to_sym][mpa.attribute.alias.to_s]
    #        end
    #
    #        in_result = {}
    #        if mpa.attribute.data_type == "string"
    #          in_result["string_data_#{level}"] = val
    #        else
    #          in_result["numeric_data_#{level}"] = val
    #        end
    #
    #      else
    #
    #        end
    #
    #      mpa.update_attributes(out_result)
    #      mpa.update_attributes(in_result)
    #
    #      end
    #      mpa.update_attribute("pbs_project_element_id", current_component.id)
    #    end
    #  end
    #
    #  #Pour chaque folder
    #  folder_result = {}
    #  @folders.map do |folder| folder.children.map{|j| j.estimation_values }.each do |mpa|
    #    %w(low most_likely high).each do |level|
    #      folder_result = { "numeric_data_#{level}" => folder.children.map{|i| i.send("#{mpa.first.attribute.alias}_#{level}") }.flatten.compact.sum}
    #    end
    #    mpa.first.update_attributes(folder_result)
    #  end
    #  end
    #end


    results = Hash.new
    ["low", "most_likely", "high"].each do |level|
      results[level.to_sym] = current_project.run_estimation_plan(params[level], level)
    end

    @module_projects = current_project.module_projects
    @results = results
    @project = current_project
    @pbs_project_element = current_component

    #@project.module_projects.each do |mp|
    #  mp.estimation_values.each do |est_val|
    #    if est_val.in_out == "output"
    #      out_result = {}
    #      @results.each do |res|
    #        ["low", "most_likely", "high"].each do |level|
    #          if est_val.attribute.data_type == "date"
    #            #out_result["date_data_#{level}"] = res[mp.pemodule.alias.to_sym][est_val.attribute.alias.to_s]
    #          elsif est_val.attribute.data_type == "string"
    #            #out_result["string_data_#{level}"] = res[mp.pemodule.alias.to_sym][est_val.attribute.alias.to_s]
    #          else
    #            out_result["numeric_data_#{level}"] = res.last[est_val.attribute.alias.to_s]
    #          end
    #        end
    #      end
    #    end
    #    est_val.update_attributes(out_result)
    #  end
    #end

    respond_to do |format|
      format.js { render :partial => "pbs_project_elements/refresh" }
    end
  end


  #Method to duplicate project and associated pe_wbs_project
  def duplicate
    begin
      old_prj = Project.find(params[:project_id])

      new_prj = old_prj.amoeba_dup   #amoeba gem is configured in Project class model

      if new_prj.save
        old_prj.save  #Original project copy number will be incremented to 1

        #Managing the compoment tree
        new_prj_components = new_prj.pe_wbs_project.pbs_project_elements

        new_prj_components.each do |new_c|
          unless new_c.is_root?
            new_ancestor_ids_list = []
            new_c.ancestor_ids.each do |ancestor_id|
               ancestor_id = PbsProjectElement.find_by_pe_wbs_project_id_and_copy_id(new_c.pe_wbs_project_id, ancestor_id).id
               new_ancestor_ids_list.push(ancestor_id)
            end
            new_c.ancestry = new_ancestor_ids_list.join('/')
            new_c.save
          end
        end
        #raise "#{RuntimeError}"
      end

      #old_prj.module_projects.each do |mp|
      #  new_mp = mp.dup
      #  new_mp.project_id = new_prj.id
      #  new_mp.save
      #end

      flash[:success] = I18n.t (:project_succesfull_duplicated)
      redirect_to "/projects" and return
    rescue
      flash["Error"] = I18n.t (:project_duplication_failled)
      redirect_to "/projects"
    end
  end


  def commit
    project = Project.find(params[:project_id])
    project.commit!
    redirect_to "/projects"
  end

  def activate
    u = current_user
    u.add_recent_project(params[:project_id])
    session[:current_project_id] = params[:project_id]
    redirect_to "/projects"
  end

  def find_use
    @project = Project.find(params[:project_id])
    @related_projects = Project.find(params[:project_id])
    respond_to do |format|
      format.js { render :partial => "projects/find_use" }
    end
  end

  def projects_global_params
    set_page_title "Project global parameters"
  end

  def project_record_number
    @projects = Project.page(params[:page]).per_page(params[:nb].to_i || 1)
    render :partial => "project_record_number"
  end

  def sort_column                                                                                                                    t
    Project.column_names.include?(params[:sort]) ? params[:sort] : "title"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def default_work_element_type
    wet = WorkElementType.find_by_alias("folder")
    return wet
  end

  #Add/Import a WBS-Activity template from Library to Project
  def add_wbs_activity_to_project
    @project = Project.find(params[:project_id])
    @pe_wbs_project_activity = @project.pe_wbs_projects.wbs_activity.first
    @wbs_project_elements_root = @project.wbs_project_element_root

    selected_wbs_activity_elt = WbsActivityElement.find(params[:wbs_activity_element])

    wbs_project_element = WbsProjectElement.new(:pe_wbs_project_id => @pe_wbs_project_activity.id, :wbs_activity_element_id => selected_wbs_activity_elt.id,
                                                :wbs_activity_id => selected_wbs_activity_elt.wbs_activity_id, :name => selected_wbs_activity_elt.name,
                                                :description => selected_wbs_activity_elt.description, :ancestry => @wbs_project_elements_root.id,
                                                :author_id => current_user.id, :copy_number => 0,
                                                :wbs_activity_ratio_id => params[:project_default_wbs_activity_ratio],  # Update Project default Wbs-Activity-Ratio
                                                :is_added_wbs_root => true)

    selected_wbs_activity_children = selected_wbs_activity_elt.children

    respond_to do |format|
      #wbs_project_element.transaction do
        if wbs_project_element.save
          selected_wbs_activity_children.each do |child|
            create_wbs_activity_from_child(child, @pe_wbs_project_activity, @wbs_project_elements_root)
          end

          #add some additional information for leaf element customization
          added_wbs_project_elements =  WbsProjectElement.find_all_by_wbs_activity_id_and_pe_wbs_project_id(wbs_project_element.wbs_activity_id, @pe_wbs_project_activity.id)
          added_wbs_project_elements.each do |project_elt|
            if project_elt.has_children?
              project_elt.can_get_new_child = false
            else
              project_elt.can_get_new_child = true
            end
            project_elt.save
          end

          @project.included_wbs_activities.push(wbs_project_element.wbs_activity_id)
          if @project.save
            flash[:notice] = I18n.t (:wbs_activity_successful_add)
          else
            flash[:error] = "#{@project.errors.full_messages.to_sentence}"
          end
        else
          flash[:error] = "#{wbs_project_element.errors.full_messages.to_sentence}"
        end
      #end
        format.html { redirect_to edit_project_path(@project, :anchor => "tabs-3")}
        format.js { redirect_to edit_project_path(@project, :anchor => "tabs-3")}
    end
  end

  def get_new_ancestors(node, pe_wbs_activity, wbs_elt_root)
    node_ancestors = node.ancestry.split('/')
    new_ancestors = []
    new_ancestors << wbs_elt_root.id
    node_ancestors.each do |ancestor|
      corresponding_wbs_project = WbsProjectElement.where("wbs_activity_element_id = ? and pe_wbs_project_id = ?", ancestor, pe_wbs_activity.id).first
      new_ancestors << corresponding_wbs_project.id
    end
    new_ancestors.join('/')
  end

  def create_wbs_activity_from_child(node, pe_wbs_activity, wbs_elt_root)
    wbs_project_element = WbsProjectElement.new(:pe_wbs_project_id => pe_wbs_activity.id, :wbs_activity_element_id => node.id, :wbs_activity_id => node.wbs_activity_id, :name => node.name,
                                                 :description => node.description, :ancestry => get_new_ancestors(node, pe_wbs_activity, wbs_elt_root), :author_id => current_user.id, :copy_number => 0)
    wbs_project_element.transaction do
      wbs_project_element.save

      if node.has_children?
        node_children = node.children
        node_children.each do |node_child|
          ActiveRecord::Base.transaction do
            create_wbs_activity_from_child(node_child, pe_wbs_activity, wbs_elt_root)
          end
        end
      end
    end
  end

  def refresh_wbs_project_elements
    @project = Project.find(params[:project_id])
    @pe_wbs_project_activity = @project.pe_wbs_projects.wbs_activity.first
    @show_hidden = params[:show_hidden]
  end

  #On edit page, select ratios according to the selected wbs_activity
  def refresh_wbs_activity_ratios
    if params[:wbs_activity_element_id].empty? || params[:wbs_activity_element_id].nil?
      @wbs_activity_ratios = []
    else
      selected_wbs_activity_elt = WbsActivityElement.find(params[:wbs_activity_element_id])
      @wbs_activity = selected_wbs_activity_elt.wbs_activity
      @wbs_activity_ratios = @wbs_activity.wbs_activity_ratios
    end
  end


end
