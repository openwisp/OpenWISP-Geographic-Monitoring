$.getJSON('', function(activity_histories){
    graphs.init({
        chart: {
            renderTo: 'activity_graph',
            zoomType: 'x',
            spacingTop: 10
        },
        title: { text: null },
        xAxis: {
            type: 'datetime',
            title: { text: null }
        },
        yAxis: {
            title: { text: null },
	    gridLineDashStyle: 'longdash',
	    maxPadding: 0.18,
	    min: -0.1,
            endOnTick: false,
            showFirstLabel: false
        },
        tooltip: {
            shared: false,
	    formatter: function() {
		return '<strong>'+ Highcharts.dateFormat('%e %b %Y, %H:%M', this.x) +'</strong><br/>'+ this.y;
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
	    name: "activity",
            data: activity_histories
        }]
    });
});
