$.getJSON('', function(activity_histories){
    graphs.init({
        chart: {
            renderTo: 'activity_graph',
            zoomType: 'x',
            spaceTop: 30
        },
        title: { text: null },
        xAxis: {
            type: 'datetime',
            title: { text: null }
        },
        yAxis: {
            title: { text: null },
            min: 0.0,
            max: 1.1,
            startOnTick: false,
            endOnTick: false,
            showFirstLabel: false
        },
        tooltip: {
            shared: true
        },
        legend: {
            enabled: false
        },
        series: [{
            data: activity_histories
        }]
    });
});
