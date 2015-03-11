class StatsController < ApplicationController
  before_filter :authenticate_user!, :load_wisp

  before_filter :owums_enabled_or_404, :only => [
    :logins, :traffic
  ]

  before_filter :datawarehouse_enabled_or_404, :only => [
    :activities
  ]

  skip_before_filter :verify_authenticity_token

  access_control do
    default :deny

    actions :logins, :traffic, :export, :activities do
      allow :wisps_viewer
      allow :wisp_access_points_viewer
      allow :wisp_associated_user_counts_viewer
    end
  end

  def logins
    response = get_owums_data('/stats/logins.json')
    render :json => response.body
  end

  def traffic
    response = get_owums_data('/stats/traffic.json')
    render :json => response.body
  end

  def export
    response = get_owums_data('/stats/export', 'post')
    # get file extension
    ext = response.content_type.split('/')[1]
    # send file for download
    send_data response.body, :filename => "chart.#{ext}"
  end

  def activities
    params[:file] = 'activities.cda'
    params[:dataAccessId] = 'activities'
    data = JSON::load(get_datawarehouse_data().body)
    render :json => data['resultset']
  end

  private

  def owums_enabled_or_404
    unless @wisp.owums_enabled?
      render :status => 404, :json => { 'detail' => 'owums not enabled for this wisp' }
      return
    end
  end

  def datawarehouse_enabled_or_404
    unless @wisp.datawarehouse_enabled?
      render :status => 404, :json => { 'detail' => 'datawarehouse not enabled for this wisp' }
      return
    end
  end

  # get data from owums
  def get_owums_data(path, method='get')
    # build URL
    url = "#{@wisp.owums_url}#{path}"
    if method == 'get'
      url = "#{url}?#{params.to_query}"
    end

    # build http request object
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = url[0, 5] == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    # get or post
    if method.downcase == 'get'
      request = Net::HTTP::Get.new(uri.request_uri)
    elsif method.downcase == 'post'
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
    end

    # credentials
    request.basic_auth(@wisp.owums_username, @wisp.owums_password)
    # return response object
    return http.request(request)
  end

  # get data from datawarehouse
  def get_datawarehouse_data(path='/pentaho/content/cda/doQuery', method='get')
    params[:solution] = 'plugin-samples'
    params[:path] = '/cda'
    # build URL
    url = "#{@wisp.datawarehouse_url}#{path}"
    if method == 'get'
      url = "#{url}?#{params.to_query}"
    end

    puts url

    # build http request object
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    # enable https if necessary
    if @wisp.datawarehouse_url[0, 5] == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # get or post
    if method.downcase == 'get'
      request = Net::HTTP::Get.new(uri.request_uri)
    elsif method.downcase == 'post'
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
    end

    # credentials
    request.basic_auth(@wisp.datawarehouse_username, @wisp.datawarehouse_password)
    # return response object
    return http.request(request)
  end
end
