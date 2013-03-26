class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  access_control do
    default :deny
    allow :wisps_viewer
  end
  
  def index
    @users = User.all
    
    add_breadcrumb(I18n.t(:Users), users_url)
  end
  
  def show
    @user = User.find(params[:id])
    
    add_breadcrumb(I18n.t(:Users), users_url)
    add_breadcrumb('%s "%s"' % [I18n.t(:User), @user.username], edit_user_url(@user.id))
  end
  
  def edit
    @user = User.find(params[:id])
    Wisp.create_all_roles_if_necessary
    @roles = Role.all_join_wisp
    
    add_breadcrumb(I18n.t(:Users), users_url)
    add_breadcrumb('%s "%s"' % [I18n.t(:Edit_user), @user.username], edit_user_url(@user.id))
  end
  
  def new
    @user = User.new
    Wisp.create_all_roles_if_necessary
    @roles = Role.all_join_wisp
  end
  
  def create
    @user = User.new(params[:user])
    
    if @user.save
      @user.roles = (params[:roles].nil? || params[:roles].length == 0) ? [] : Role.find_all_by_id(params[:roles])      
      flash[:notice] = t(:Account_registered)
      redirect_to users_path
    else
      @roles = Role.all_join_wisp
      render :action => "new"
    end
  end

  def update
    @user = User.find(params[:id])
    # if update succeed
    if @user.update_attributes(params[:user])
      # edit roles
      @user.roles = Role.find_all_by_id(params[:roles])
      flash[:notice] = t(:Account_updated)
      redirect_to(users_url)
    else
      @roles = Role.all_join_wisp
      render :action => "edit"
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.has_no_roles!
    @user.destroy
    
    redirect_to(users_url)
  end
end