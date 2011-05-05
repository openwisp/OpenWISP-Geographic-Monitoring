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
