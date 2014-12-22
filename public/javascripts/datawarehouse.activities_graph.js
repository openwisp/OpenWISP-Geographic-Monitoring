graphs.drawActivityArchive = function(params){
    // default values
    params = params || {
        'el': 'activities_graph',
        'stats_el': 'activities-interval',
        'from': $('#paramStartDate').val(),
        'to': $('#paramStopDate').val(),
        'mac': $('#parammacaddress').val(),
        'url': $('#activities_graph').attr('data-url')
    };

    // set locale (calendar days, ecc.)
    owumsGraphs.setLocale()

    var to = params.to.split('/').reverse().join('-'),
        from = params.from.split('/').reverse().join('-'),
        querystring = '?parammacaddress=' + params.mac + '&paramStartDate=' + from + '&paramStopDate=' + to,
        dates = $("#paramStartDate, #paramStopDate").datepicker({
            minDate: '-10y',
            maxDate: new Date(),
            defaultDate: "+1w",
            showButtonPanel: true,
            changeMonth: true,
            changeYear: true,
            yearRange: 'c-3:',
        });

    $.getJSON(owgm.path(params.url + querystring), function(activities){
        graphs.init({
            chart: {
                renderTo: params.el,
                zoomType: 'x',
                plotBorderWidth: 1
            },
            colors: ['#913FA6'],
            title: { text: null },
            xAxis: {
                type: 'datetime',
                title: { text: null },
                labels: { style: {fontWeight: 'bold'}, step:2 },
                endOnTick: false,
                maxPadding: 0,
                minPadding: 0,
                gridLineWidth: 2,
                minorGridLineWidth: 1,
                dateTimeLabelFormats: {
                    day: '%e %B',
                    hour: '%e %B, %H:%M',
                    minute: '%e %B, %H:%M',
                    second: '%e/%m, %H:%M'
                }
            },
            yAxis: {
                title: { text: null },
                labels: {style: {fontWeight: 'bold'}},
                minorGridLineWidth: 0.3,
                minorTickInterval: 'auto',
                min: -0.01,
                max: 1.01,
                showFirstLabel: false,
                showLastLabel: false
            },
            tooltip: {
                shared: false,
                formatter: function() {
                    return '<strong>'+ Highcharts.dateFormat('%a %e %b %Y, %H:%M', this.x) +'</strong><br/>'+ this.y;
                },
                backgroundColor: {
                    linearGradient: [0, 0, 0, 50],
                    stops: [
                        [0, '#FFFFFF'],
                        [1, '#E0E0E0']
                    ]
                },
                borderWidth: 1,
                borderColor: '#AAA'
            },
            legend: {
                enabled: false
            },
            credits: {
                enabled: false
            },
            plotOptions: {
                series: {
                    marker: {
                        enabled: false,
                        fillColor: '#FFFFFF',
                        lineWidth: 2,
                        lineColor: null,
                        states: {
                            hover: { enabled: true }
                        }
                    }
                }
            },
            series: [{
                data: activities
            }]
        });
    });
    $('#'+params.el).parents('.block.stats').addClass('loaded');
}
