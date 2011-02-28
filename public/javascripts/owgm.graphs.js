var graphs = {
    activityGraphControls: '#act_controls',
    howto: '.howto',
    lastWeek: '.last_week',
    lastDay: '.last_day',
    lastMonth: '.last_month',
    activityGraphDiv: '#activity_graph',
    activityGraphData: [],
    activityGraph: undefined,
    days_to_graph: '30',
    // Slow Internet Explorer flashcanvas fix. By sending less data, graphing is faster
    ie_days_to_graph: '10',

    drawActivityGraph: function() {
        if (owgm.exists(graphs.activityGraphDiv)){
            $.jqplot.config.enablePlugins = true;
            var _url = location.href.concat('?days_ago=').concat(graphs.days_to_graph);
            $.getJSON(_url, function(data){
                if (data.length > 0) {
                    $.each(data, function() {
                        if (this.activity_history) {
                            graphs.activityGraphData.push([this.activity_history.start_time, this.activity_history.status]);
                        }
                    });
                    graphs.activityGraph = $.jqplot($(graphs.activityGraphDiv).attr('id'), [ graphs.activityGraphData ], {
                        highlighter: {sizeAdjust:12, tooltipAxes:'y', formatString:'%s'},
                        cursor: {zoom:true, constrainZoomTo:'x', showVerticalLine:true, showTooltip:false},
                        seriesColors: ["#FF9900"],
                        axes: {
                            yaxis: {min:0, max:1, tickOptions:{formatString:'%.2f'}, rendererOptions:{padding:0}},
                            xaxis: {
                                min:graphs.daysAgo(7),
                                max:graphs.today(),
                                renderer:$.jqplot.DateAxisRenderer,
                                rendererOptions:{tickRenderer:$.jqplot.CanvasAxisTickRenderer, padding:0},
                                tickOptions:{formatString:'%H:00 %d/%m', angle:-35}
                            }
                        }
                    });
                    graphs.enableActivityControls();
                }
            });
        }
    },

    enableActivityControls: function() {
        $(graphs.activityGraphControls+' '+graphs.lastDay).live('click', function(event){
            graphs.activityGraph.resetZoom();
            graphs.activityGraph.axes.xaxis.min = graphs.daysAgo(1);
            graphs.activityGraph.replot();
            event.preventDefault();
        });
        $(graphs.activityGraphControls+' '+graphs.lastWeek).live('click', function(event){
            graphs.activityGraph.resetZoom();
            graphs.activityGraph.axes.xaxis.min = graphs.daysAgo(7);
            graphs.activityGraph.replot();
            event.preventDefault();
        });
        $(graphs.activityGraphControls+' '+graphs.lastMonth).live('click', function(event){
            graphs.activityGraph.resetZoom();
            graphs.activityGraph.axes.xaxis.min = graphs.daysAgo(30);
            graphs.activityGraph.replot();
            event.preventDefault();
        });

        $(graphs.activityGraphControls).show();
        $(graphs.howto).show();
    },

    daysAgo: function(days) {
        return new Date().setDate(graphs.today().getDate()-days);
    },

    today: function() {
        return new Date();
    }
};
