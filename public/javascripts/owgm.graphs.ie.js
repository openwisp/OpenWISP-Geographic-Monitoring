graphs.drawActivityGraph = function() {
    if (owgm.exists(graphs.activityGraphDiv)){
        $.jqplot.config.enablePlugins = true;
        var _url = location.href.concat('?days_ago=').concat(graphs.ie_days_to_graph);
        $.getJSON(_url, function(data){
            if (data.length > 0) {
                $.each(data, function() {
                    if (this.activity_history) {
                        graphs.activityGraphData.push([this.activity_history.start_time, this.activity_history.status]);
                    }
                });
                graphs.activityGraph = $.jqplot($(graphs.activityGraphDiv).attr('id'), [ graphs.activityGraphData ], {
                    highlighter: {sizeAdjust:12, tooltipAxes:'y', formatString:'%s'},
                    cursor: {show:false},
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
            }
        });
    }
}
