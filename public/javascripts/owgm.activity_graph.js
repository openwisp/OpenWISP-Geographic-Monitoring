$.getJSON('', function(activity_histories){
    graphs.init({
        chart: {
            renderTo: 'activity_graph',
            zoomType: 'x',
            spacingTop: 10,
	    plotBorderWidth: 1
        },
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
            minorGridLineColor: '#E0E0E0',
            minorGridLineWidth: 0.5,
            minorTickInterval: 'auto',
	    maxPadding: 0.18,
	    min: -0.1,
            endOnTick: false,
            showFirstLabel: false
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
