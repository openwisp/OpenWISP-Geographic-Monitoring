/*
# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2010 CASPUR (wifi@caspur.it)
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

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

/* document.ready callback... */
$(document).ready(function() {
    $.ajaxSetup({ cache: false });
    owgm.enableJavascript();
    owgm.ajaxQuickSearch();
    owgm.ajaxLoading();
    if (typeof(gmaps) !== 'undefined') {
        gmaps.drawGoogleMap();
    }
});


/****** OWGM scope ******/

var owgm = {

    /*** Settings and Variables ***/
    quickSearchDiv: '#access_points_quicksearch',
    loadingDiv: '#loading',
    noJsDiv: '.no_js',

    /*** Application Specific Functions ***/
    enableJavascript: function() {
        $(owgm.noJsDiv).hide();
    },

    exists: function (selector) {
        return ($(selector).length > 0);
    },

    ajaxQuickSearch: function() {
        var inputField = $(this.quickSearchDiv).find('input[type=text]');
        inputField.observe(function() {
            $(owgm.loadingDiv).fadeIn();
            inputField.parent('form').submit();
            $(owgm.loadingDiv).ajaxStop(function(){$(this).fadeOut();});
        }, 1);
    },

    path: function(path) {
        var _curr = window.location.pathname;
        var _params = window.location.search;
        if (path.charAt(0) === '/') {
            if (_curr.substr(1, owums.subUri.length) === owums.subUri) {
                return '/'+owums.subUri+path+_params;
            } else {
                return path+_params;
            }
        } else {
            return _curr+'/'+path+_params;
        }
    },

    highlightAccessPointsReport: function(tableId, upClass, downClass, statusId, highLowId, percentId) {
        var status = $(statusId);
        var highLow = $(highLowId);
        var percent = $(percentId);

        var findToHighlight = function() {
            var statusVal = status.val();
            var highLowVal = highLow.val();
            var percentVal = percent.val();

            var highlight = function(elem) {
                elem.removeClass('highlighted');

                if (statusVal === '1') {
                    var tdVal = $('td'+upClass, elem).html();
                    if (tdVal) {
                        if (highLowVal === '<') {
                            if (parseInt(tdVal.slice(0,-1)) < parseInt(percentVal)){
                                elem.addClass('highlighted');
                            }
                        } else if (highLowVal === '>') {
                            if (parseInt(tdVal.slice(0,-1)) > parseInt(percentVal)){
                                elem.addClass('highlighted');
                            }
                        }
                    }
                } else if (statusVal === '0') {
                    var tdVal = $('td'+downClass, elem).html();
                    if (tdVal) {
                        if (highLowVal === '<') {
                            if (parseInt(tdVal.slice(0,-1)) < parseInt(percentVal)){
                                elem.addClass('highlighted');
                            }
                        } else if (highLowVal === '>') {
                            if (parseInt(tdVal.slice(0,-1)) > parseInt(percentVal)){
                                elem.addClass('highlighted');
                            }
                        }
                    }
                }

            };

            $(tableId+' tr').each(function(){
                highlight($(this));
            });
        };

        $(statusId+','+highLowId+','+percentId).change(function(){
            if (status.val() !== '' && highLow.val() !== '' && percent.val() !== '') {
                findToHighlight();
            } else if (status.val() === '' && highLow.val() === '' && percent.val() === '') {
                $('.highlighted').removeClass('highlighted');
            }
        });
    },

    ajaxLoading: function() {
        $('[data-remote=true]').live('click', function(){
            $(owgm.loadingDiv).fadeIn();
        }).ajaxStop(function(){
            $(owgm.loadingDiv).fadeOut();
        });
    },

    dateRangePicker: function(){
        if (owgm.exists('#from') && owgm.exists('#to')) {
            var dates = $( "#from, #to" ).datepicker({
                minDate: '-6m',
                maxDate: owgm.today(),
                defaultDate: "+1w",
                showButtonPanel: true,
                changeMonth: true,
                changeYear: true,
                yearRange: 'c-10:',
                onSelect: function( selectedDate ) {
                    var option = this.id == "from" ? "minDate" : "maxDate",
                            instance = $( this ).data( "datepicker" ),
                            date = $.datepicker.parseDate(
                                    instance.settings.dateFormat || $.datepicker._defaults.dateFormat,
                                    selectedDate, instance.settings
                                    );
                    dates.not( this ).datepicker( "option", option, date );
                }
            });
        }
    },

    daysAgo: function(days) {
        return new Date().setDate(owgm.today().getDate()-days);
    },

    today: function() {
        return new Date();
    }
};

/************************/
