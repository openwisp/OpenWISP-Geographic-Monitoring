# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def paginate(to_paginate)
    will_paginate to_paginate, :next_label => t(:Next), :previous_label => t(:Prev)
  end

  def link_to_locale(locale)
    link_to(image_tag("locale/#{locale}.jpg", :size => "26x26"), :locale => locale)
  end

  def link_to_sort(text, column = nil)
    column ||= text.downcase

    order = case params[:order]
    when 'asc' then 'desc'
    when 'desc' then 'asc'
    else 'desc'
    end

    if column == params[:column]
      dom_class = {:class => 'ordered_'+order}
    else
      dom_class = {}
    end

    url = params.merge({:column => column, :order => order})
    link_to text, {:method => :get, :url => url}, {:href => url_for(url), :remote => true}.merge(dom_class)
  end

  def link_to_back
    unless current_page?(root_path) || current_page?(root_path.chop) || current_page?(hotspots_path)
      link_to t(:Back), :back
    end
  end

  def for_ie(opts = {:version => nil, :if => nil}, &block)
    to_include = with_output_buffer(&block)
    open_tag = "<!--[if "
    open_tag << "#{opts[:if]} " unless opts[:if].nil?
    open_tag << "IE"
    open_tag << " #{opts[:version]}" unless opts[:version].nil?
    open_tag << "]>"
    (open_tag+to_include+"<![endif]-->").html_safe
  end
end
