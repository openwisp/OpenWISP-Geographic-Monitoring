class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  access_control do
    default :deny
    allow :wisps_viewer
  end
  
  def index
    @users = User.all
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def edit
    @user = User.find(params[:id])
    Wisp.create_all_roles_if_necessary
    @roles = Role.all_join_wisp
  end
  
  def new
    @user = User.new
    Wisp.create_all_roles_if_necessary
    @roles = Role.all_join_wisp
  end
  
  def create
    @user = User.new(params[:user])

    @selected_roles = (params[:roles].nil? || params[:roles].length == 0) ? [] : params[:roles]

    if @user.save
      @user.roles = @selected_roles

      respond_to do |format|
        flash[:notice] = t(:Account_registered)
        format.html { redirect_to(users_path()) }
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @user = User.find(params[:id])
    
    #@roles = Role.all_join_wisp
    @params = params[:roles]

    @selected_roles = Role.find_all_by_id(params[:roles])

    if @user.update_attributes(params[:user])
      @user.roles = @selected_roles

      respond_to do |format|
        flash[:notice] = t(:Account_updated)
        format.html { redirect_to(users_path()) }
      end
    else
      respond_to do |format|
        #flash[:alert] = t(:Errors)
        # qui va forse fatto redirect
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.has_no_roles!
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_path()) }
    end
  end
  
end