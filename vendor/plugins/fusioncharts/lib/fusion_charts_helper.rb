module FusionChartsHelper
  require 'nokogiri'
  def render_chart(c)
    Nokogiri::HTML::Builder.new(:encoding => 'utf-8') do |doc|
      doc.div do
        doc.div :id => c.name
        doc.script :type => 'text/javascript' do
          js_str = "var chart = new FusionCharts('#{compute_public_path(c.type+'.swf', 'charts')}', '#{c.name}', '#{c.w}', '#{c.h}','0','1');" << "\n"
          js_str << ( c.url ? "chart.setDataURL(\"#{c.url}\");" : "chart.setDataXML(\"#{h(c.to_xml).strip}\");" ) << "\n"
          js_str << "chart.render('#{c.name}');" << "\n"
          doc.cdata js_str
        end
      end
    end.doc.root.children.to_html
  end
end
