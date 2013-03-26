class GroupsController < ApplicationController
  before_filter :authenticate_user!#, :load_wisp
  
  # implement access control
  
  def index    
    @groups = Group.all_join_wisp
    
    add_breadcrumb(I18n.t(:Group_list), groups_url)
  end
  
  def new
    @group = Group.new
    
    add_breadcrumb(I18n.t(:Group_list), groups_url)
    add_breadcrumb(I18n.t(:New_group), new_group_url)
  end
  
  def create
    @group = Group.new(params[:group])

    if @group.save
      flash[:notice] = t(:Group_created)
      redirect_to(groups_url)
    else
      render :action => "new"
    end
  end
  
  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      flash[:notice] = t(:Group_modified)
      redirect_to(groups_url)
    else
      render :action => "edit"
    end
  end
  
  def edit
    @group = Group.find(params[:id])
    
    add_breadcrumb(I18n.t(:Group_list), groups_url)
    add_breadcrumb('%s "%s"' % [I18n.t(:Edit_group), @group.name], edit_group_url(@group.id))
  end
  
  def destroy
    @group = Group.find(params[:id])
    @group.destroy
    redirect_to(groups_url)
  end
end
