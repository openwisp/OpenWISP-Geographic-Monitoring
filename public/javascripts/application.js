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
    }
};

/************************/
