owumsGraphs.drawTraffic = function(params){
    // default values
    params = params || {
        'el': 'traffic_graph',
        'stats_el': 'stats-interval',
        'from': $('#from').val(),
        'to': $('#to').val(),
        'mac': $('#mac').val()
    }
    
    querystring = '?from=' + params.from + '&to=' + params.to + '&called-station-id=' + params.mac
    
    params.url = params.url || $('#'+params.el).attr('data-url')
    params.export_url = params.export_url || $('#'+params.stats_el).attr('data-url')

    $.getJSON(owgm.path(params.url + querystring), function(traffic){
        owumsGraphs.init({
            chart: {
                renderTo: params.el,
                type: 'column',
                zoomType: 'xy'
            },
            title: { text: null },
            credits: { enabled: false },
            legend: { borderWidth: 0 },
            colors: ['#8AD96D', '#913FA6', '#BF2424'],
            plotOptions: {
                column: { stacking: 'normal' },
                series: {
                    marker: {
                        fillColor: '#FFFFFF',
                        lineWidth: 2,
                        lineColor: null
                    }
                }
            },
            xAxis: {
                gridLineWidth: 1,
                tickLength: 2,
                type: 'datetime',
                maxZoom: 7 * 24 * 3600000,
                labels: {step:2}
            },
            yAxis: {
                title: { text: null },
                labels: {
                    formatter: function() { return owumsGraphs.bytes_formatter(this.value, true); }
                }
            },
            tooltip: {
                formatter: function() {
                    var dateStr = Highcharts.dateFormat('%A, %b %e, %Y', this.x);
                    var nameStr = '<span style="color:'+this.series.color+'">'+this.series.name+'</span>';
                    var valStr = '<strong>'+owumsGraphs.bytes_formatter(this.y, true)+'</strong>';
                    return '<span style="font-size:10px">'+dateStr+'<br/>'+nameStr+'<span style="color:black">: </span>'+valStr+'</span>';
                }
            },
            exporting: {
                url: owgm.path(params.export_url),
                width: 1200,
                buttons: {
                    printButton: {enabled: false},
                    exportButton: {verticalAlign: 'bottom', y:-5}
                }
            },
            series: traffic
        });
        $('#'+params.el).parents('.block.stats').addClass('loaded');
    });
}