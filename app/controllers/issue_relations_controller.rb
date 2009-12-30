# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class IssueRelationsController < ApplicationController
  before_filter :find_project, :authorize
  
  def new
    @relation = IssueRelation.new(params[:relation])
    @relation.issue_from = @issue
    if params[:relation] && !params[:relation][:issue_to_id].blank?
      @relation.issue_to = Issue.visible.find_by_id(params[:relation][:issue_to_id])
    end
    @relation.save if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
      format.js do
        render :update do |page|
          page.replace_html "relations", :partial => 'issues/relations'
          if @relation.errors.empty?
            page << "$('relation_delay').value = ''"
            page << "$('relation_issue_to_id').value = ''"
          end
        end
      end
    end
  end
  
  def union
    if (to_issue = Issue.find_by_id(params[:union][:issue_to_id])).nil? || @issue == to_issue
      redirect_to :controller => "issues", :action => 'show', :id => @issue
      flash[:error] = l(:error_issue_not_found_for_union)
    else
      if to_issue.init_journal(@issue.author, @issue.subject + "\n\n"  + @issue.description).save!
        @issue.journals.each { |journal| journal.update_attributes(:journalized => to_issue) }
        if !@issue.attachments.empty?
          @issue.attachments.each { |attachment| attachment.update_attributes(:container => to_issue) }
        end
        @issue.reload
        @issue.destroy
        redirect_to :controller => "issues", :action => 'show', :id => to_issue
        flash[:notice] = l(:notice_successful_issue_union)
      else
        redirect_to :controller => "issues", :action => 'show', :id => @issue
        flash[:error] = l(:notice_not_authorized)
      end
    end
  end

  def destroy
    relation = IssueRelation.find(params[:id])
    if request.post? && @issue.relations.include?(relation)
      relation.destroy
      @issue.reload
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
      format.js { render(:update) {|page| page.replace_html "relations", :partial => 'issues/relations'} }
    end
  end
  
private
  def find_project
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
