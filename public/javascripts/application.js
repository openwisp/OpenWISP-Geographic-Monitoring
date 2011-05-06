// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

/* document.ready callback... */
$(document).ready(function() {
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
    quickSearchDiv: '#hotspots_quicksearch',
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

    highlightHotspotsReport: function(tableId, upClass, downClass, statusId, highLowId, percentId) {
        var status = $(statusId);
        var highLow = $(highLowId);
        var percent = $(percentId);

        status.observe(function(){
            if (this.val() != '' && highLow.val() != '' && percent.val() != '') {
                findToHighlight();
            }
        });
        highLow.observe(function(){
            if (this.val() != '' && status.val() != '' && percent.val() != '') {
                findToHighlight();
            }
        });
        percent.observe(function(){
            if (this.val() != '' && highLow.val() != '' && status.val() != '') {
                findToHighlight();
            }
        });

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
                maxDate: owgm.today(),
                defaultDate: "+1w",
                showButtonPanel: true,
                changeMonth: true,
                onSelect: function(selectedDate) {
                    var option = this.id == "from" ? "minDate" : "maxDate",
                            instance = $(this).data("datepicker"),
                            date = $.datepicker.parseDate(instance.settings.dateFormat, selectedDate, instance.settings);
                    dates.not(this).datepicker("option", option, date);
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
