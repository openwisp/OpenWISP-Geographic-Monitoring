owumsGraphs.drawLogins = function(params){
    // default values
    params = params || {
        'el': 'logins_graph',
        'stats_el': 'stats-interval',
        'from': $('#from').val(),
        'to': $('#to').val(),
        'mac': $('#mac').val()
    }
    
    params.url = params.url || $('#'+params.el).attr('data-url')
    params.export_url = params.export_url || $('#'+params.stats_el).attr('data-url')
    
    querystring = '?from=' + params.from + '&to=' + params.to + '&called-station-id=' + params.mac
    
    $.getJSON(owgm.path(params.url + querystring), function(logins){
        owumsGraphs.init({
            chart: {
                renderTo: params.el,
                type: 'column',
                zoomType: 'xy'
            },
            title: { text: null },
            credits: { enabled: false },
            legend: { borderWidth: 0 },
            colors: ['#478EDD', '#FF9431'],
            plotOptions: {
                column: { stacking: 'normal' }
            },
            xAxis: {
                gridLineWidth: 1,
                tickLength: 2,
                maxZoom: 7 * 24 * 3600000,
                type: 'datetime',
                labels: {step:2}
            },
            yAxis: {
                title: { text: null },
                allowDecimals: false
            },
            exporting: {
                url: owgm.path(params.export_url),
                width: 1200,
                buttons: {
                    printButton: {enabled: false},
                    exportButton: {verticalAlign: 'bottom', y:-5}
                }
            },
            series: logins
        });
        $('#'+params.el).parents('.block.stats').addClass('loaded');
    });
}
