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

module PeWbsProjectsHelper
  #Generate an powerful Work Breakdown Structure
    def generate_wbs(pbs_project_element, project, tree, gap)
      #Root is always display
      if pbs_project_element.is_root?
        tree << "<ul >
           #{wbs_root_links(pbs_project_element, project)}"
        end

      if pbs_project_element.has_children?
        gap = gap + 2
        tree << "<ul class='sortable' style='margin-left:#{gap}px; border-left: 1px solid black; padding-left: 8px;''>"
        pbs_project_element.children.sort_by(&:position).each do |c|
          if c.work_element_type.alias == "folder"
            tree << wbs_folder_links(c, project)
          else
            tree << wbs_navigation_links(c)
          end
          generate_wbs(c, project, tree, gap)
        end
        tree << "</ul>"
      else
        #Nothing
      end

      return tree
    end

    def wbs_navigation_links(c)
      "<li class='#{ c.id == session[:pbs_project_element_id] ? 'selected' : '' }'  >
        <div class='block_label'>
          <div>
            #{image_tag c.work_element_type.peicon.nil? ? '' : c.work_element_type.peicon.icon.url(:small)}
            #{ link_to(c.name, { :controller => 'pbs_project_elements', :action => 'selected_pbs_project_element', :id => c.id}, :remote => true, :class => "libelle") }
          </div>
        </div>
        <div class='block_link'>
          #{ link_to "", edit_pbs_project_element_path(c, :project_id => @project.id), :remote => true, :class => 'bl edit' if can? :edit_a_pbs_project_element, PbsProjectElement}
          #{ link_to "", c, confirm: 'Are you sure?', method: :delete, :remote => true, :class => 'bl delete' if can? :delete_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'up', :pbs_project_element_id => c.id, :pe_wbs_project_id => c.pe_wbs_project_id, :project_id => @project.id}, :remote => true, :class => 'bl up ' if can? :move_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'down' ,:pbs_project_element_id => c.id, :pe_wbs_project_id => c.pe_wbs_project_id, :project_id => @project.id}, :remote => true, :class => 'bl down ' if can? :move_a_pbs_project_element, PbsProjectElement }
        </div>
      </li>"
    end


    def wbs_folder_links(c, project)
      "<li class='#{ c.id == session[:pbs_project_element_id] ? 'selected' : '' }' >
        <div class='block_label'>
          <div onClick='toggle_folder(this);' >
            #{image_tag c.work_element_type.peicon.nil? ? '' : c.work_element_type.peicon.icon.url(:small)}
            #{ link_to(c.name, { :controller => 'pbs_project_elements', :action => 'selected_pbs_project_element', :id => c.id}, :remote => true, :class => "libelle") }
          </div>
        </div>
        <div class='block_link'>
          #{ link_to("", { :controller => 'pbs_project_elements', :action => 'new', :pe_wbs_project_id => project.pe_wbs_project.id, :comp_parent_id => c.id, :type_component => "folder" }, :remote => true, :class => 'bl new_folder ') if can? :add_a_pbs_project_element, PbsProjectElement}
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'new', :pe_wbs_project_id => project.pe_wbs_project.id, :comp_parent_id => c.id, :type_component => "undefined" },:remote => true, :class => 'bl new_undefined ' if can? :add_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'new', :pe_wbs_project_id => project.pe_wbs_project.id, :comp_parent_id => c.id, :type_component => "link" }, :remote => true, :class => 'bl new_link ' if can? :add_a_pbs_project_element, PbsProjectElement}
          #{ link_to "", edit_pbs_project_element_path(c, :project_id => @project.id), :remote => true, :class => 'bl edit' if can? :edit_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", c, confirm: 'Are you sure?', method: :delete, :remote => true, :class => 'bl delete' if can? :delete_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'up', :pbs_project_element_id => c.id, :pe_wbs_project_id => c.pe_wbs_project_id, :project_id => @project.id}, :remote => true, :class => 'bl up ' if can? :move_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'down' ,:pbs_project_element_id => c.id, :pe_wbs_project_id => c.pe_wbs_project_id, :project_id => @project.id}, :remote => true, :class => 'bl down ' if can? :move_a_pbs_project_element, PbsProjectElement }
        </div>
      </li>"
    end

    def wbs_root_links(pbs_project_element, project)
      "<li>
        <div class='block_label'>
          <div onClick='toggle_folder(this);' >
            #{ image_tag pbs_project_element.work_element_type.peicon.nil? ? '' : pbs_project_element.work_element_type.peicon.icon.url(:small) }
            #{ link_to(project.title, { :controller => 'pbs_project_elements', :action => 'selected_pbs_project_element', :id => pbs_project_element.id}, :remote => true, :class => "libelle ") }
          </div>
        </div>
        <div class='block_link'>
          #{ link_to("", { :controller => 'pbs_project_elements', :action => 'new', :pe_wbs_project_id => project.pe_wbs_project.id, :comp_parent_id => pbs_project_element.id, :type_component => "folder" }, :remote => true, :class => 'bl new_folder') if can? :add_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'new', :pe_wbs_project_id => project.pe_wbs_project.id, :comp_parent_id => pbs_project_element.id, :type_component => "" }, :remote => true, :class => 'bl new_undefined ' if can? :add_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", { :controller => 'pbs_project_elements', :action => 'new', :pe_wbs_project_id => project.pe_wbs_project.id, :comp_parent_id => pbs_project_element.id, :type_component => "link" }, :remote => true, :class => 'bl new_link '  if can? :add_a_pbs_project_element, PbsProjectElement }
          #{ link_to "", edit_pbs_project_element_path(pbs_project_element, :project_id => @project.id), :remote => true, :class => 'bl edit' if can? :edit_a_pbs_project_element, PbsProjectElement }
        </div>
      </li>"
    end
end