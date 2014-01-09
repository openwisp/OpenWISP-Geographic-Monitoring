class GroupsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_wisp, :wisp_breadcrumb, :only => [:list]
  
  skip_before_filter :verify_authenticity_token, :only => [:toggle_monitor, :toggle_count_stats]
  
  access_control do
    default :deny
    allow :wisps_viewer
    
    actions :list do
      allow :wisp_access_points_viewer, :of => :wisp, :if => :wisp_loaded?
    end
    
    actions :index, :new, :create, :update, :edit, :destroy, :toggle_monitor, :toggle_count_stats do
      allow :wisp_access_points_viewer
    end
  end
  
  def index
    @groups = Group.all_accessible_to(@current_user)
    
    add_breadcrumb(I18n.t(:Group_list), groups_url)
  end
  
  def list
    @groups = Group.all_join_wisp('wisp_id IS NULL OR wisp_id = ?', [@wisp.id])
    
    add_breadcrumb(I18n.t(:Group_list_of_wisp, :wisp => @wisp.name), wisp_groups_path(@wisp))
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
      flash[:notice] = t(:Group_modified, :group => @group.name)
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
  
  def toggle_monitor
    group = Group.find(params[:id])
    group.monitor!
    respond_to do |format|
      format.json{
        image = view_context.image_path(group.monitor ? 'accept.png' : 'delete.png')
        render :json => { 'monitor' => group.monitor, 'image' => image }
      }
    end
  end
  
  def toggle_count_stats
    group = Group.find(params[:id])
    group.count_stats!
    respond_to do |format|
      format.json{
        image = view_context.image_path(group.count_stats ? 'accept.png' : 'delete.png')
        render :json => { 'count_stats' => group.count_stats, 'image' => image }
      }
    end
  end
end
