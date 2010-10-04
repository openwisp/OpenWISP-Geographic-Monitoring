# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  SPINNER_IMG = '<img src="'+RAILS_SUB_URI+'images/spinner.gif"'+' />'
  
  def remote_paginate(to_paginate, options)
    will_paginate to_paginate, :renderer => RemoteLinkRenderer, 
                               :next_label => t(:Next), 
                               :previous_label => t(:Prev),
                               :div_id => options[:div_id]
  end
  
  def link_to_sort(text, column = nil)
    column ||= text.downcase
    
    order = case params[:order]
    when 'asc' then 'desc'
    when 'desc' then 'asc'
    else 'desc'
    end
    
    if column == params[:column]
      dom_class = 'order_by '+order
    else
      dom_class = order
    end
    
    url = params.merge({:column => column, :order => order})
    link_to_remote text, {:method => :get, :url => url}, {:href => url_for(url), :class => dom_class}
  end
  
  def link_to_back
    unless current_page?(root_path) || current_page?(root_path.chop) || current_page?(hotspots_path)
      link_to t(:Back), :back
    end
  end
  
  def observe_field_with_spinner(div_id, field, opts={})
    spinner_js = {
      :before => "if($('#{div_id}').select('span').length==0){$('#{div_id}').insert({'top':'<span class="+'spin'+">#{SPINNER_IMG}</span>'})}",
      :success => "$('#{div_id}').select('span')[0].remove()"
    }
    observe_field field, opts.merge(spinner_js)
  end
  
  
  ######### Extend WillPaginate to implement Ajax Pagination ########
  class RemoteLinkRenderer < WillPaginate::LinkRenderer
    def prepare(collection, options, template)
      @remote = options.delete(:remote) || {}
      @div_id = options.delete(:div_id) || nil
      super
    end

  protected
    def page_link(page, text, attributes = {})
      spinner = @div_id ? {:loading => "$('#{@div_id}').insert({'bottom':'<span class="+'spin'+">#{SPINNER_IMG}</span>'})"} : {}
      @template.link_to_remote(text, {:url => url_for(page), :method => :get}.merge(@remote).merge(spinner), attributes.merge(:href => url_for(page)))
    end
  end
  ##################################################################
end
