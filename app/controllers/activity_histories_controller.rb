# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'spreadsheet'

class ActivityHistoriesController < ApplicationController
  before_filter :authenticate_user!, :load_wisp, :wisp_breadcrumb
  skip_before_filter :verify_authenticity_token, :only => [:export]

  access_control do
    default :deny

    actions :index, :show, :export, :send_report do
      allow :wisps_viewer
      allow :wisp_activity_histories_viewer, :of => :wisp, :if => :wisp_loaded?
    end
  end

  def index
    @showstatus = CONFIG['showstatus']
    @from = Date.strptime(params[:from], I18n.t('date.formats.default')) rescue 365.days.ago.to_date
    @to = Date.strptime(params[:to], I18n.t('date.formats.default')) rescue Date.today
    @access_points = AccessPoint.with_properties.activated(@to).of_wisp(@wisp)

    crumb_for_report
  end

  def show
    @activity_history = ActivityHistory.where(:access_point_id => params[:access_point_id]).older_than(30.days.ago)

    respond_to do |format|
      format.json { render :json => @activity_history }
    end
  end

  # accepts only POST
  def export

    @showstatus = CONFIG['showstatus']
    # prepare header row
    header = [
      I18n.t('Name'),
      I18n.t('Site_description'),
      I18n.t('Activation_date'),
      I18n.t('Address'),
      I18n.t('City'),
      I18n.t('Description'),
      I18n.t('Public'),
      I18n.t('Up'),
      I18n.t('Down')
    ]

    if @showstatus
        header.push(I18n.t('Status'))
    end
    # entity body is a json string, decode it to get the data for the excel
    @access_points = ActiveSupport::JSON.decode(request.body.read)

    # load spreadsheet gem and Date
    # prepare file
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    today = Date.today().strftime('%d-%m-%Y')
    sheet1.name = 'Report %s' % [today]
    header.each_with_index do |cell, i|
      sheet1.row(0).push cell
    end

    sheet1.row(0).height = 25
    heading_cells = Spreadsheet::Format.new :color => :black,
                                     :weight => :bold,
                                     :size => 11,
                                     :vertical_align => :middle,
                                     :horizontal_align => :center
    centered_cells = Spreadsheet::Format.new :horizontal_align => :center

    sheet1.column(0).width = 20
    sheet1.column(1).width = 22
    sheet1.column(2).width = 18
    sheet1.column(3).width = 20
    sheet1.column(4).width = 16
    sheet1.column(5).width = 22
    sheet1.column(6).width = 16
    #Value of status could be quite long
    sheet1.column(9).width = 22

    sheet1.row(0).default_format = heading_cells

    @access_points.each_with_index do |access_point, i|
      # init new row
      row = sheet1.row(1+i)
      # write data in the row
      row.push access_point[0], access_point[1], access_point[2], access_point[3], access_point[4], access_point[5], access_point[6], access_point[7], access_point[8]
      if @showstatus == true
         row.push access_point[9]
      end
      # center the activation date column
      row.set_format(2, centered_cells)
      # center the last 3 columns
      3.times{ |c|
        row.set_format(c+6, centered_cells)
      }
    end

    # write excel in tmp folder
    book.write '%s/tmp/availability-report.xls' % [Rails.root]

    respond_to do |format|
      format.json { render :json => { :result => 'success', 'url' => wisp_send_report_path } }
    end
  end

  def send_report
    today = Date.today().strftime('%d-%m-%Y')
    file = '%s/tmp/availability-report.xls' % [Rails.root]
    begin
      # send file and trigger download
      send_file file, :filename => "report-#{today}.xls", :type =>  "application/vnd.ms-excel"
      # delete file
      File.delete(file)
    rescue Errno::ENOENT
      # returns 410 http status code if file has been already deleted
      head :gone
    end
  end

  private

  def crumb_for_report
    add_breadcrumb I18n.t(:Availability_report_for, :wisp => @wisp.name), wisp_availability_report_path(@wisp)
  end
end
