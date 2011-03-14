# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def link_to_locale(locale)
    html_opts = locale.to_sym == I18n.locale ? {:class => "current_#{locale}"} : {}
    link_to(image_tag("locale/#{locale}.jpg", :size => "26x26"), {:locale => locale}, html_opts)
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
    unless current_page?(root_path) || current_page?(root_path.chop) || current_page?(wisps_path)
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

  def auth?(role, object=nil)
    current_user && current_user.has_role?(role, object)
  end

  def hotspots_with_or_without_wisp_path(wisp)
    wisp ? wisp_hotspots_path(wisp) : hotspots_path
  end
end
