module FusionCharts
  require File.dirname(__FILE__) + '/fusion_charts_helper'
  require 'nokogiri'

  class FusionChart
    include FusionCharts
    attr_accessor :data, :options, :labels

    def initialize(options={})
      @options = defaults.merge!(options)
      @data = Array.new
    end

    def defaults
      {:type => 'Column3D', :h => 300, :w => 600, :name => 'fusion_chart', :url => nil}
    end

    def options(options={})
      @options.merge!(options)
    end

    def type
      self.options[:type]
    end

    def w
      self.options[:w]
    end

    def h
      self.options[:h]
    end

    def name
      self.options[:name]
    end

    def url
      self.options[:url]
    end

    def to_xml
      save_option = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
      Nokogiri::XML::Builder.new do |xml|
        xml.graph(self.options) do
          chart_xml(xml)
          xml.styles do
            xml.definition do
              xml.style(:name => :myShadow, :type => :shadow, :angle => 45, :distance => 3)
              xml.style(:name => :titleFont, :type => :font, :size => 18)
              xml.style(:name => :subTitleFont, :type => :font, :size => 14)
            end
            xml.application do
              xml.apply(:toObject => :DATAPLOT, :styles => :myShadow)
              xml.apply(:toObject => :CAPTION, :styles => :titleFont)
              xml.apply(:toObject => :SUBCAPTION, :styles => :subTitleFont)
            end
          end
        end
      end.to_xml(:encoding => 'utf-8', :save_with => save_option)
    end

    def chart_xml(xml)
      self.data.each do |line|
        xml.set(line)
      end
    end

  end

  class MSFusionChart < FusionChart

    def initialize(options={})
      super(options)
      @data = Hash.new
    end

    def defaults
      {:type => 'MSColumn3D', :h => 300, :w => 600, :name => 'ms_fusion_chart'}
    end

    def chart_xml(xml)
      xml.categories do
        self.labels.each do |label|
          xml.category :label => label
        end
      end
      self.data.each do |d|
        xml.dataset(:seriesName => d[0]) do
          d[1].each do |value|
            xml.set :value => value
          end
        end
      end
    end
  end

end
