/*
# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
