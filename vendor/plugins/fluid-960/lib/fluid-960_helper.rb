module Fluid960Helper
  def fluid960_stylesheets
    style = stylesheet_link_tag('960/css/reset','960/css/text','960/css/grid','960/css/layout','960/css/nav', '960/css/notification')
    style += "<!--[if IE 6]><link rel=\"stylesheet\" type=\"text/css\" href=\"960/css//ie6.css\" media=\"screen\" /><![endif]-->"
    style += "<!--[if gte IE 7]><link rel=\"stylesheet\" type=\"text/css\" href=\"960/css//ie.css\" media=\"screen\" /><![endif]-->"
  end
end
