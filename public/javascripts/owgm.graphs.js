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

var graphs = {
    locales: [
        {
            locale: 'it',
            triggerIfExists: '.current_it',
            lang: {
                resetZoom: 'Reimposta Zoom',
                months: ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto',
                    	'Settembre', 'Ottobre', 'Novembre', 'Dicembre'],
                weekdays: ['Domenica', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato']
            }
        },
        {
            locale: 'en',
            triggerIfExists: '.current_en',
            lang: {resetZoom: 'Reset Zoom'}
        }
    ],

    // Private functions and variables
    _plotted: [],
    init: function(_graph) {
        $(document).ready(function() {
            graphs.setLocale();
            graphs._plotted.push(new Highcharts.Chart(_graph));
        });
    },

    setLocale: function() {
        $.each(graphs.locales, function(){
            if (owgm.exists(this.triggerIfExists)) {
                Highcharts.setOptions({global:{useUTC:false},lang: this.lang});
            }
        });
    }
};

