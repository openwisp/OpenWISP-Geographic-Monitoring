$.getJSON(owgm.path('activity_histories.json'), function(activity_histories){
    graphs.init({
        chart: {
            renderTo: 'activity_histories_graph',
            zoomType: 'x',
	    plotBorderWidth: 1
        },
        colors: ['#913FA6'],
        title: { text: null },
        xAxis: {
            type: 'datetime',
            title: { text: null },
	    labels: {style: {fontWeight: 'bold'}, step:2},
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
            data: activity_histories
        }]
    });
});
