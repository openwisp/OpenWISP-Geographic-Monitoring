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

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

/* document.ready callback... */
$(document).ready(function() {
    $.ajaxSetup({ cache: false });
    owgm.enableJavascript();
    owgm.ajaxQuickSearch();
    owgm.ajaxLoading();
    owgm.initGmap();
    owgm.initNotice();
    owgm.initAccessPointList();
    owgm.initMainMenu();
    owgm.initDynamicColumns();
    owgm.initTooltip();

    if($('#access-point-info').length) {
        owgm.initToggleBox();
        owgm.initEditManagerEmail();
        owgm.initApAlertSettings();
    }
});


/****** OWGM scope ******/

var owgm = {

    /*** Settings and Variables ***/
    noJsDiv: '.no_js',

    /*** Application Specific Functions ***/
    enableJavascript: function() {
        $(owgm.noJsDiv).hide();
    },

    exists: function (selector) {
        return ($(selector).length > 0);
    },

    ajaxQuickSearch: function() {
        $('#q').delayedObserver(0.8, function(value, object) {
            owgm.toggleLoading('show');
            object.parent('form').submit();
        });
    },

    subUri: 'owgm',

    path: function(path) {
        var _curr = window.location.pathname;
        var _params = window.location.search;
        if (path.charAt(0) === '/') {
            return path+_params;
        } else {
            return _curr+'/'+path+_params;
        }
    },

    initGmap: function(){
        if (typeof(gmaps) !== 'undefined') {
            // bind click event to the <a> that toggles the map container
            $(gmaps.mapToggle).click(function(e){
                // cache some stuff
                var container = $(gmaps.mapContainer),
                    is_visible = container.is(':visible'),
                    arrow = container.parent().find('.arrow');
                // prevent default link behaviour
                e.preventDefault();
                // toggle class hidden
                $(this).toggleClass('hidden');
                // toggle container and initialize gmap if necessary
                container.slideToggle('slow', function(){
                    if(!is_visible && gmaps.map == undefined){
                        gmaps.drawGoogleMap();
                    }
                });
                if(!is_visible){
                    arrow.html(arrow.attr('data-hide'));
                }
                else{
                    arrow.html(arrow.attr('data-show'));
                }
            });
            gmaps.drawGoogleMap();
        }
    },

    initAccessPointList: function(){
        if($('#access_points_list').length){
            owgm.initBatchSelection();
            owgm.initBatchActions();
            owgm.initFavourite();
            owgm.initPublic();
            owgm.paginator();
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
        $('#access_points_paginate a[data-remote=true]').live('click', function(){
            owgm.toggleLoading('show');
            $('body, .container12, .pagination a').css('cursor', 'progress');
        })
        $(document).ajaxStop(function(){
            owgm.toggleLoading('hide');
            $('body, .container12').css('cursor', 'auto');
            $('.pagination a').css('cursor', 'pointer');
            $('.select-all-checkbox').each(function(){
                this.checked = false
            });
            owgm.accessPointsDynamicColumns();
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
    },

    paginator: function(){
        if($('#access_points_paginate').length > 0){
            $("#combobox select").combobox({
                position: 'bottom',
                // links to edit per_page querystring value
                links: '#access_points_paginate .pagination a',
                form: '#access_points_quicksearch form',
                // maximum custom value
                max_value: 100,
                // executed at the beginning of _create method
                beforeCreate: function(){
                    try {
                        var initial_value = localStorage.getItem('pagination') || false,
                            selected_value = $('#combobox option:selected').val();
                        // if initial value is stored in the browser cache and is different from the default value
                        if(initial_value && selected_value !== initial_value){
                            // select the cached value
                            $('#combobox option:selected').removeAttr('selected');
                            $('#combobox option[value='+initial_value+']').attr('selected', true);
                        }
                        // else if cached value is the same as the default value
                        else if(initial_value && selected_value === selected_value){
                            // remove localstorage item to avoid pointlessly reloading the list of access points
                            localStorage.removeItem('pagination');
                        }
                    } catch(e){}

                },
                afterCreate: function(){
                    try {
                        // load initial value
                        initial_value = localStorage.getItem('pagination') || false;
                        if(initial_value){
                            this.onChange(initial_value, 'afterCreate', false);
                        }
                    } catch(e){ }
                },
                // function that is executed when selected value changes
                onChange: function(ui, event, reload){
                    if(reload === undefined){
                        reload = true;
                    }

                    var val;
                    if(typeof ui === 'object'){
                        val = $(ui.item.option).val();
                    }
                    else if(typeof ui === 'string' && typeof parseInt(ui) === 'number'){
                        val = ui;
                    }
                    else{
                        // this might yeld unexpected results.. check!
                        return;
                    }

                    // function to update the href or action attributes with correct pagination value
                    // $el: jquery element, attribute: string, value: string
                    var updateUrl = function($el, attribute, value){
                        // cache attribute value
                        var attr_value = $el.attr(attribute),
                        // and querystring value for pagination
                            key = 'per=';
                        // if querystring doesn't contains key just append the key at the end
                        if(attr_value.indexOf(key) < 0){
                            // if no querystring at all add the ?
                            key = (attr_value.indexOf('?') < 0) ? key = '?'+key : '&'+key;
                            // change the attribute
                            $el.attr(attribute, attr_value + key + value);
                        }
                        // otherwise use regular expression to change the value
                        else{
                            attr_value = attr_value.replace(
                                new RegExp(
                                    "(per=)(\\d+)"
                               ), "$1" + value
                            )
                            $el.attr(attribute, attr_value);
                        }
                    }
                    // update each pagination link
                    $(this.links).each(function(i, el){
                        updateUrl($(el), 'href', val);
                    });
                    // store value for later retrieval
                    try {
                        localStorage.setItem('pagination', val);
                    } catch(e){}
                    // trigger click
                    var first_link = $('#access_points_paginate .page a').eq(0);
                    if(first_link.length){
                        first_link.trigger('click');
                    }
                    else{
                        owgm.refreshPage(val);
                    }
                    // if form is defined
                    if(this.form){
                        // update action
                        updateUrl($(this.form), 'action', val);
                    }
                }
            });
        }
    },

    // refreshes current page even if no pagination link exists
    refreshPage: function(page){
        var current = $('.current a'),
            url = $('#access_points_quicksearch form').attr('action'),
            pos = url.indexOf('?per=');

        if(page){
            if(pos){
                url = url.substring(0, pos) + '?per=' + page;
            }
            else{
                url = url + '?per=' + page;
            }
        }

        if(!page && current.length){
            current.trigger('click');
        }
        else{
            $('#access_points_paginate').append('<a class="hidden" id="tmp_update" href="'+url+'" data-remote="true"></a>');
            $('#tmp_update').trigger('click');
            $('#tmp_update').remove();
        }
    },

    exportReport: function(export_url, file){
        this.toggleProgress();
        // local variables
        var data = [], // init array that will contain data for the excel
            $tr = $('#report tbody tr'), // the table rows
            $highlighted = $('#report tbody tr.highlighted'), // the highlighted table rows
            $elements = $highlighted.length ? $highlighted : $tr; // if any highlighted row, then pass the highlighted ones, otherwise all the rows
        // loop over each row
        $elements.each(function(i, tr){
            var row = []; // init array that will contain row info
            // loop over each table cell of current row
            $(tr).find('td').each(function(i, td){
                // push the text of this cell in the "row" array
                row.push($(td).text());
            })
            // add current row array to the "data" array
            data.push(row);
        });
        // POST the JSON string to Rails
        $.ajax({
            type: 'post',
            dataType: 'json',
            url: export_url,
            data: data,
            // if file excel has been generated successfully
            success: function(data){
                if(data.result == 'success'){
                    // download file
                    window.location.href = data.url;
                    owgm.toggleProgress();
                }
            },
            // otherwise alert user (exceptional case)
            error: function(xhr, response) {
                alert("Error: "+ xhr.status);
                owgm.toggleProgress();
            }
        });
    },

    // reset highlighting
    resetHighlighting: function(msg){
        var rows = $('.highlighted');
        // if any
        if(rows.length){
            // reset highlighting
            rows.removeClass('highlighted');
            // and restore default values for the selects
            $('#export-controls').parent().find('select').val(this.defaultValue)
        }
        // otherwise alert message
        else{
            alert(msg);
        }
    },

    // toggle progress indicator
    toggleProgress: function(id){
        // if no id specified defaults to progress-ind
        if(!id){
            id = 'progress-ind';
        }
        // create div if necessary
        if($('#'+id).length < 1){
            $('body').append('<div id="'+id+'"></div>');
            // center to the window and show
            $('#'+id).css({
                top: ($(window).height() - 55) / 2,
                left: ($(window).width() - 55) / 2
            }).fadeIn(250);
        }
        // otherwise if div has been already created before just toggle with a quick fade animation
        else{
            $('#'+id).fadeToggle(250);
        }
    },

    initNotice: function(){
        $('.message .close').click(function(e){
            e.preventDefault();
            $(this).parent().fadeToggle(400);
        });
    },

    toggleProperty: function(url, completed){
        var el = $(this);
        $.ajax({
            url: url,
            type: 'POST'
        }).done(function(result) {
            if(completed && typeof completed == 'function'){ completed(result) }
        }).fail(function(result){
            alert('ERROR');
        });
    },

    initGroupList: function(){
        $('.toggle-monitor, .toggle-count-stats').click(function(e){
            e.preventDefault();
            var el = $(this);
            owgm.toggleProperty(el.attr('data-href'), function(result){
                el.find('img').attr('src', result.image)
            });
        });
    },

    toggleOverlay: function(closeCallback){
        var mask = $('#mask'),
            close = $('.close'),
            overlay = $('.overlay');

        if(!mask.length){
            $('body').append('<div id="mask"></div>')
            mask = $('#mask');
            // init ESC key to close
            $(document).keyup(function(e){
                if(e.keyCode == 27){
                    closeOverlay();
                }
            })
        }

        var closeOverlay = function(){
            if(close.attr('data-confirm-message') !== undefined && !window.confirm(close.attr('data-confirm-message'))){
               return false;
            }
            overlay.fadeOut();
            mask.fadeOut();
            if(closeCallback && typeof(closeCallback) === "function" ){
                closeCallback();
            }
            return true;
        }

        if(!overlay.is(':visible')){
            mask.css('opacity','0').show().fadeTo(250, 0.7);
            overlay.centerElement().fadeIn(250);
        }
        else{
            closeOverlay();
        }
        if($.data(close.get(0), 'events') === undefined){
            close.click(function(e){
                closeOverlay();
            });
        }
    },

    toggleLoading: function(action){
        var $loading = $('#loading-indicator');
        if(!$loading.length){
            $('body').append('<div id="loading-indicator"></div>')
            $loading = $('#loading-indicator');
        }
        $loading.togglePop(action);
    },

    initSelectGroup: function(select_group_url){
        $('#group-row').css('cursor','pointer').click(function(e){
            owgm.openGroupSelection({
                'url': select_group_url,
                'init': function(){
                    // mark current group as selected
                    var group_id = $('#group-info').attr('data-groupid');
                    $('#group_'+group_id).addClass('selected');
                },
                'afterSelect': function(){
                    // query the database, update group name, close overlay and remove HTML
                    var url = $(this).attr('data-href');
                    response = $.ajax({
                        'url': url,
                        'type': 'POST'
                    }).done(function(result){
                        owgm.toggleLoading();
                        owgm.toggleOverlay();
                        $('#group-info').html(result.name).attr('data-groupid', result.id);
                        $('#select-group').remove();
                    }).fail(function(){
                        alert('ERROR');
                    });
                },
                'beforeSelect': function(){
                    // there can be only one item selected
                    $(this).parent().find('.selected').removeClass('selected');
                    owgm.toggleLoading();
                }
            });
        });
    },

    openGroupSelection: function(options){
        var opts = $.extend({
            'url': false,
            'init': null,
            'beforeSelect': null,
            'afterSelect': null
        }, options);

        if(opts.url===false){ throw('url parameter must be specified') }

        owgm.toggleLoading();
        // retrieve remote group list
        $.ajax({
            'url': opts.url,
        }).done(function(result){
            // insert HTML and open overlay
            $('body').append(result);
            owgm.toggleOverlay(function(){$('#select-group').remove()});
            owgm.toggleLoading();
            $select_group = $('#select-group');
            // determine css max-height
            var max_height = $(window).height()-$(window).height()/4;
            $select_group.css('max-height', max_height);
            $('#scroller').css('max-height', max_height);
            // center overlay in the middle of the screen
            $select_group.centerElement();
            // reposition when resizing
            $(window).resize(function(){
                $select_group.centerElement();
            });
            $('#select-group table').customSelectable({
                'init': opts.init,
                'beforeSelect': opts.beforeSelect,
                'afterSelect': opts.afterSelect,
            });
        })
    },

    initBatchSelection: function(){
        // init jQuery UI selectable widget
        $("#access_points").selectable({
            filter: "tr",
            delay: 80,
            start: function(event, ui) {
                // blur focus from quicksearch otherwise unexpected behaviour might occur when using keyboard shortcuts
                var activeEl = $(document.activeElement);
                if(activeEl.attr('name') == 'q'){
                    activeEl.trigger('blur');
                }
            }
        });

        // select or deselect all
        $(".select-all").click(function(e){
            e.preventDefault();
            var checkbox = $('.select-all-checkbox');
            checkbox.trigger('click');
        });
        $(".select-all-checkbox").change(function(e){
            if(this.checked){
                $("#access_points tr").addClass('ui-selected');
            }
            else{
                $("#access_points tr").removeClass('ui-selected');
            }
        })
    },

    openGroupBatchSelection: function(){
        var post_url = $('.batch-actions select').attr('data-change-property-href');
        // at least one ap must be selected
        if($("#access_points tr.ui-selected").length < 1){
            alert($('.batch-actions select').attr('data-fail-message'));
        }
        else{
            owgm.openGroupSelection({
                'url': $('.batch-actions select').attr('data-select-group-href'),
                'afterSelect': function(){
                    owgm.toggleLoading();
                    // this function changes the group in batch
                    owgm.batchChangeProperty(post_url, 'group_id', $(this).attr('data-group-id'));
                    owgm.toggleOverlay(function(){
                        // close call back of overlay
                        owgm.toggleLoading();
                        $('#select-group').remove();
                    });
                }
            });
        }
    },

    batchChangeProperty: function(post_url, property_name, property_value){
        var selected_access_points_id = [],
            selected_access_points = $("#access_points tr.ui-selected");

        // ensure some access points are selected
        if(selected_access_points.length < 1){
            alert($('.batch-actions select').attr('data-fail-message'));
            return false;
        }

        // fill ap id list
        selected_access_points.each(function() {
            var ap_id = $(this).attr('data-ap-id');
            selected_access_points_id.push(ap_id)
        });
        // ajax request to change group
        $.ajax({
            url: post_url,
            type: 'POST',
            contentType: 'application/json',
            dataType: 'json',
            data: JSON.stringify({ "property_name": property_name, "property_value": property_value, "access_points": selected_access_points_id })
        }).fail(function(xhr, status, error){
            // in case of error return error message;
            // might happen if there is an internal server error and its not possible to parse the response as json
            // in case no error is show it will be hard to find the bug
            try{
                alert((JSON.parse(xhr.responseText)).details);
            }
            catch(e){
                alert('ERROR');
            }
        }).done(function(){
            // update UI
            owgm.refreshPage();
            // reselect after refresh
            $(document).ajaxStop(function(){
                selected_access_points.each(function(i, e){
                    $('#access_points tr[data-ap-id='+$(e).attr('data-ap-id')+']').addClass('ui-selectee ui-selected');
                });
                selected_access_points = $();
            });
        });
    },

    initBatchActions: function(){
        // url to POST
        var post_url = $('.batch-actions select').attr('data-change-property-href');
        // action select
        $(".batch-actions select").each(function(i, el){
            // determine position of autocomplete menu
            var position = i === 0 ? 'top' : 'bottom';
            // init combobox widget
            $(el).combobox({
                position: position,
                // function that is executed when selected value changes
                onChange: function(ui, autocomplete){
                    var select = $(ui.item.option).parent(),
                        option = $(ui.item.option).val();

                    function resetSelection(){
                        // reset selection .. yeah cumbersome..
                        setTimeout(function(){
                            $(".batch-actions .ui-combobox-input").autocomplete('widget').find('li a').eq(0).trigger('click');
                        }, 50);
                    }

                    // if no action just return here
                    if(option == '0'){ return false }

                    // otherwise ensure some access points are selected
                    if($("#access_points tr.ui-selected").length < 1){
                        alert(select.attr('data-fail-message'));
                        resetSelection()
                        return false;
                    }

                    var property_name,
                        property_value;

                    if(option == 'group'){
                        owgm.openGroupBatchSelection(post_url);
                    }
                    else if(option == 'favourite_0'){
                        property_name = 'favourite';
                        property_value = false;
                    }
                    else if(option == 'favourite_1'){
                        property_name = 'favourite';
                        property_value = true;
                    }
                    else if(option == 'public_0'){
                        property_name = 'public';
                        property_value = false;
                    }
                    else if(option == 'public_1'){
                        property_name = 'public';
                        property_value = true;
                    }
                    if(option != 'group'){
                        owgm.batchChangeProperty(post_url, property_name, property_value);
                    }
                    resetSelection();
                },
                afterCreate: function(){
                    var container = $(el).parent();
                    container.find('.ui-combobox input').click(function(e){
                        e.preventDefault(); container.find('.ui-combobox a').trigger('click')
                    });
                }
            });
        });

        // keyboard shortcuts
        $(document).keydown(function(e){
            // ESC: deselect all the access points
            if(e.keyCode == 27){
                $("#access_points tr.ui-selected").removeClass('ui-selectee').removeClass('ui-selected');
            }
            // CTRL + A: select all the access points
            else if(e.ctrlKey && e.keyCode == 65){
                e.preventDefault();
                $("#access_points tr").addClass('ui-selectee ui-selected');
            }
            // CTRL + D: add to favourite
            else if(e.ctrlKey && e.keyCode == 68){
                e.preventDefault();
                owgm.batchChangeProperty(post_url, 'favourite', true);
            }
            // SHIFT + D: remove from favourite
            else if(e.shiftKey && e.keyCode == 68){
                e.preventDefault();
                owgm.batchChangeProperty(post_url, 'favourite', false);
            }
            // CTRL + G: open group selection
            else if(e.ctrlKey && e.keyCode == 71){
                e.preventDefault();
                owgm.openGroupBatchSelection();
            }
            // CTRL + P: publish (will overwrite print shortcut on some systems)
            else if(e.ctrlKey && e.keyCode == 80){
                e.preventDefault();
                owgm.batchChangeProperty(post_url, 'public', true);
            }
            // SHIFT + P: remove from favourite
            else if(e.shiftKey && e.keyCode == 80){
                e.preventDefault();
                owgm.batchChangeProperty(post_url, 'public', false);
            }
            // SHIFT + RIGHT-ARROW: next page
            else if(e.shiftKey && e.keyCode == 39){
                e.preventDefault();
                $('.next a').trigger('click');
            }
            // SHIFT + LEFT-ARROW: prev page
            else if(e.shiftKey && e.keyCode == 37){
                e.preventDefault();
                $('.prev a').trigger('click');
            }
        });
    },

    initMainMenu: function(){
        $('.second-level').each(function(i, el){
            width = $(el).width()
            $(el).find('.third-level').attr('style', 'left: '+width+'px !important');
        });
    },

    initDynamicColumns: function(){
        if($('#access_points_list').length){
            $(window).resize(function(e){
                owgm.accessPointsDynamicColumns();
            });
            owgm.accessPointsDynamicColumns();
        }
        if($('#group_list').length){
            $(window).resize(function(e){
                owgm.groupsDynamicColumns();
            });
            owgm.groupsDynamicColumns();
        }
        if('#last-logins'){
            $(window).resize(function(e){
                owgm.latestOnlineUsersDynamicColumns();
            });
            owgm.latestOnlineUsersDynamicColumns();
        }
    },

    accessPointsDynamicColumns: function(){
        var width = $(window).width();

        if(width <= 1100){
            if($('.mac_address', '#access_points_list').eq(0).is(':visible')){
                $('.mac_address', '#access_points_list').hide();
            }
        }
        else{
            if(!$('.mac_address', '#access_points_list').eq(0).is(':visible')){
                $('.mac_address', '#access_points_list').show();
            }
        }

        if(width <= 1200){
            if($('.site_description', '#access_points_list').eq(0).is(':visible')){
                $('.site_description', '#access_points_list').hide();
            }
        }
        else{
            if(!$('.site_description', '#access_points_list').eq(0).is(':visible')){
                $('.site_description', '#access_points_list').show();
            }
        }

        if(width <= 1300){
            if($('.ip_address', '#access_points_list').eq(0).is(':visible')){
                $('.ip_address', '#access_points_list').hide();
            }
        }
        else{
            if(!$('.ip_address', '#access_points_list').eq(0).is(':visible')){
                $('.ip_address', '#access_points_list').show();
            }
        }

        if(width <= 1500){
            if($('.activation_date', '#access_points_list').eq(0).is(':visible')){
                $('.activation_date', '#access_points_list').hide();
            }
        }
        else{
            if(!$('.activation_date', '#access_points_list').eq(0).is(':visible')){
                $('.activation_date', '#access_points_list').show();
            }
        }
    },

    groupsDynamicColumns: function(){
        var width = $(window).width();

        if(width <= 1100){
            if($('.favourite', '#group_list').eq(0).is(':visible')){
                $('.favourite', '#group_list').hide();
            }
        }
        else{
            if(!$('.favourite', '#group_list').eq(0).is(':visible')){
                $('.favourite', '#group_list').show();
            }
        }

        if(width <= 1230){
            if($('.wisp', '#group_list').eq(0).is(':visible')){
                $('.wisp', '#group_list').hide();
            }
        }
        else{
            if(!$('.wisp', '#group_list').eq(0).is(':visible')){
                $('.wisp', '#group_list').show();
            }
        }
    },

    latestOnlineUsersDynamicColumns: function(){
        var width = $(window).width(),
            $ip_column = $('#last-logins .ip'),
            $association_date_column = $('#last-logins .association-date');

        if(width <= 1170){
            if($ip_column.eq(0).is(':visible')){
                $ip_column.hide();
            }
        }
        else{
            if(!$ip_column.eq(0).is(':visible')){
                $ip_column.show();
            }
        }

        if(width <= 1050){
            if($association_date_column.eq(0).is(':visible')){
                $association_date_column.hide();
            }
        }
        else{
            if(!$association_date_column.eq(0).is(':visible')){
                $association_date_column.show();
            }
        }
    },

    initTooltip: function(){
        $(".hastip").simpletip({
            fixed: true,
            boundryCheck: false,
            position: 'top',
            showTime: 100,
            hideTime: 50,
            onBeforeShow: function(){
                var a = this.getParent(),
                    title = a.attr('title');
                a.attr('data-title', title);
                a.removeAttr('title');
                this.update(title.replace(/\\n/g, '<br>'));
            },
            onHide: function(){
                var a = this.getParent(),
                    title = a.attr('data-title');
                a.attr('title', title);
                a.removeAttr('data-title');
            }
        });
    },

    initFavourite: function(){
        $('a.toggle-favourite').live('click',function(e){
            e.preventDefault();
            var el = $(this);
            owgm.toggleProperty(el.attr('data-href'), function(result){
                el.find('img').attr('src', result.image)
                if(el.attr('data-add')){
                    var new_title = result.favourite === true ? el.attr('data-remove') : el.attr('data-add');
                    el.attr('data-title', new_title);
                    el.attr('title', new_title);
                    $('.tooltip').text(new_title);
                }
            });
        })
    },

    initPublic: function(){
        $('#access_points_list a.toggle-public').live('click', function(e){
            e.preventDefault();
            var el = $(this);
            owgm.toggleProperty(el.attr('data-href'), function(result){
                el.find('img').attr('src', result.image)
            });
        });
    },

    initToggleBox: function(){
        $('a.toggle').click(function(e){
            // cache some stuff
            var container = $(this).parents('.box').find('.container'),
                is_visible = container.is(':visible'),
                arrow = container.parent().find('.arrow');
            // prevent default link behaviour
            e.preventDefault();
            // toggle class hidden
            $(this).toggleClass('hidden');
            // toggle container and initialize gmap if necessary
            container.slideToggle('slow', function(){
                // on animation complete;
            });
            if(!is_visible){
                arrow.html(arrow.attr('data-hide'));
            }
            else{
                arrow.html(arrow.attr('data-show'));
            }
            if ($(this).parents('.box').attr('id') == 'stats-usage' && !is_visible) {
                owumsGraphs.drawLogins();
                owumsGraphs.drawTraffic();
            }
            if ($(this).parents('.box').attr('id') == 'stats-activities' && !is_visible) {
                graphs.drawActivityArchive();
            }
        });
    },

    loadLastLogins: function(onSuccess){
        owgm.owums_not_working = owgm.owums_not_working || false;
        // if we previously discovered this feature isn't working stop here
        if(owgm.owums_not_working){
            return false;
        }
        // get online users and update UI
        response = $.get(location.pathname + '/last_logins', function(response){
            $('#last-logins .loading').hide();
            $('#last-logins tbody').html(response);
            $('#last-logins table').slideDown(255);
            // handy onSuccess callback
            if (onSuccess) {
                onSuccess();
            }
        // in case of errors show message
        }).error(function(){
            $('#last-logins .message').show();
            $('#last-logins .loading').hide();
            owgm.owums_not_working = true;
        });
        return true;
    },

    monitorLastLogins: function(milliseconds){
        setInterval(function(){
            shown = !$('#last-logins h2 a').hasClass('hidden');
            if(shown && window.isActive){
                owgm.loadLastLogins(); // refresh
            }
        }, milliseconds);
    },

    initEditManagerEmail: function(){
        owgm.editManager = true;

        $('#manager_email_input').focus(function(e){
            $(this).removeClass('inactive');
        }).blur(function(e){
            var $this = $(this),
                value = $this.val()
                url = $this.attr('data-url');

            // if invalid add error class
            if(value != '' && this.validity.valid === false && owgm.editManager === true) {
                $this.addClass('field_with_errors');
            }
            // if valid
            else{
                var $input = $(this);

                // remove error class and make inactive
                $input.addClass('inactive');
                $input.removeClass('field_with_errors');

                // save result to DB
                if (owgm.editManager === true && this.value != this.defaultValue) {
                    $.post(url, { manager_email: value })
                    // error case
                    .error(function(xhr){
                        alert(JSON.parse(xhr.responseText).errors.manager_email[0]);
                        $input.removeClass('inactive').addClass('field_with_errors');
                        $input.trigger('focus');
                    });
                }
                // cancel
                else{
                    this.value = this.defaultValue
                }

            }
        }).keydown(function(e){
            // if pressing enter
            if(e.keyCode == 13) {
                owgm.editManager = true;
                $(this).trigger('blur');
            }
            // if pressing esc
            else if (e.keyCode == 27) {
                owgm.editManager = false;
                $(this).trigger('blur');
            }
        });

        // focus on field when clicking on row
        $('#email-row').click(function(e){
            $('#manager_email_input').trigger('focus');
        });
    },

    initGroupAlertSettings: function(){
        // activate jquery tag-it plugin
        $("#group_alerts_email").tagit();
        // hide or show alert settings depending on wether monitoring is active or not
        $('#group_monitor').change(function(e){
            if(this.checked){
                $('#alert-settings').slideDown(300);
            }
            else{
                $('#alert-settings').slideUp(300);
                $('#group_alerts').removeAttr('checked').trigger('change');
            }
        }).trigger('change');

        // cache inputs
        var group_alert_related_inputs = $('#alert-settings input[type=text], #alert-settings input[type=number], ul.tagit')

        // activate or deactivate input related fields depending on main alerts boolean
        $('#group_alerts').change(function(e){
            if(this.checked){
                group_alert_related_inputs.removeAttr('readonly').removeClass('disabled');
                //email_addresses.removeClass('disabled');
            }
            else{
                group_alert_related_inputs.attr('readonly', 'readonly').addClass('disabled');
                //email_addresses.addClass('disabled');
            }
        }).trigger('change');

        // if clicking on a deactivated field, enable the feature
        group_alert_related_inputs.click(function(e){
            if($(this).attr('readonly') == 'readonly'){
                $('#group_alerts').attr('checked', 'checked').trigger('change');
                $(this).trigger('focus');
            }
        });
    },

    initApAlertSettings: function () {
        // WARNING: this method is really messy.. TODO: improve readability and architecture
        var post_url = $('#manager_email_input').attr('data-url');

        var adjustPopUpWidth = function () {
            $('#alert-settings-popup').width($('#alert-settings').width() + 1);
        };

        var updateHTML = function () {
            $.get(window.location.href).done(function (response) {
                // get response fragment we need
                var new_html = $(response).find('#alert-settings-customized-row').html();
                // replace HTML with fresh data
                $('#alert-settings-customized-row').html(new_html);
                adjustPopUpWidth();
            })
        }

        $(window).resize(function () {
            // assign same width as ap info table
            adjustPopUpWidth();
        }).load(function () {
            // assign same width as ap info table
            adjustPopUpWidth();
        });

        var topDistance = $('#access-point-info').offset().top + $('#access-point-info').height();
        $('#alert-settings-popup').css('top', topDistance-1);

        // mouse enter: show; mouse leave: hide
        $('#access-point-info').on('mouseenter', '#alert-settings.monitored, #alert-settings-popup', function (e) {
            $('#alert-settings-popup').show();
        }).on('mouseleave', '#alert-settings.monitored, #alert-settings-popup', function (e) {
            $('#alert-settings-popup, #alert-settings-popup').hide();

            if (owgm.editAlertSettings) {
                var threshold_up = $('#alerts_threshold_up').val();
                var threshold_down = $('#alerts_threshold_down').val();

                $.post(post_url, {
                    alerts_threshold_up: threshold_up,
                    alerts_threshold_down: threshold_down
                }).
                done(function () {
                    updateHTML();
                    owgm.editAlertSettings = false;
                });
            }

        });

        var changeAlertsImage = function (action) {
            var image = $('.toggle-alerts img'),
                image_name = image.attr('src');

            if (action === undefined && image_name.indexOf('accept.png') > 0) {
                action = 'disable';
            } else if (action === undefined) {
                action = 'enable';
            }

            if (action == 'enable') {
                image_name = image_name.replace('delete.png', 'accept.png')
            } else if (action == 'disable') {
                image_name = image_name.replace('accept.png', 'delete.png')
            }

            image.attr('src', image_name);

            return (action == 'enable') ? 'true' : 'false';
        };

        $('#access-point-info').on('click', 'a.toggle-alerts', function (e) {
            var action = changeAlertsImage();

            $.post($(this).attr('data-href'), {
                alerts: action
            }).done(function () {
                updateHTML();
            }).
            error(function () {
                alert('ERROR');
            });
        });

        $('#access-point-info').delegate('#reset-alert-settings', 'click', function (e) {
            e.preventDefault();

            changeAlertsImage('disable');

            owgm.editAlertSettings = false;
            $('#alert-settings-popup').hide();

            $.post(post_url, {
                reset: 'true'
            }).done(function () {
                updateHTML();
            });
        });

        $('#access-point-info').on('click', '#alert-settings-popup label', function (e) {
            $(this).parents('tr').find('input').trigger('focus');
        });

        $('#access-point-info').on('focus', '#alert-settings-popup .edit-in-place', function (e) {
            $(this).removeClass('inactive');
        }).on('blur', '#alert-settings-popup .edit-in-place', function (e) {
            $(this).addClass('inactive');

            if (this.value == '') {
                this.value = this.defaultValue;
            }
        }).on('keyup', '#alert-settings-popup .edit-in-place', function (e) {

            // block negative values
            if ($(this).val() < 0 || e.keyCode == 189) {
                this.value = this.defaultValue
                e.preventDefault();
                return false;
            }

            owgm.editAlertSettings = true;
            // if pressing enter
            if (e.keyCode == 13) {
                $(this).trigger('blur');
            }
            // if pressing esc
            else if (e.keyCode == 27) {
                owgm.editManager = false;
                this.value = this.defaultValue;
                $(this).trigger('blur');
            }
        }).on('change', '#alert-settings-popup .edit-in-place', function (e) {
            owgm.editAlertSettings = true;
        });
    }
};

/************************/

$.fn.customSelectable = function(options){
    var opts = $.extend({
        'init': null,
        'beforeSelect': null,
        'afterSelect': null
    }, options);
    var table = $(this);
    table.addClass('selectable');
    if(opts.init){ opts.init.apply(table) }
    table.find('tbody tr').click(function(e){
        if(opts.beforeSelect){ opts.beforeSelect.apply($(this)) }
        el = $(this);
        var checkbox = el.find('input[type=checkbox]');
        checkbox.attr('checked', !checkbox.attr('checked'))
        el.toggleClass('selected');
        if(opts.afterSelect){ opts.afterSelect.apply($(this)) }
    });
    return table;
}

$.fn.centerElement = function(){
    var el = $(this);
    el.css('top', ($(window).height() - (el.height() + parseInt(el.css('padding-top')) + parseInt(el.css('padding-bottom'))) ) / 2)
    .css('left', ($(window).width() - (el.width() + parseInt(el.css('padding-left')) + parseInt(el.css('padding-right'))) ) / 2);
    return el;
}
$.fn.togglePop = function(action, speed){
    action = action || 'auto'
    speed = speed || 150;
    var el = $(this);
    el.centerElement();
    if(action == 'auto'){
        el.is(':visible') ? el.fadeOut(speed) : el.fadeIn(speed);
    }
    else if(action == 'show'){
        el.fadeIn(speed);
    }
    else if(action == 'hide'){
        el.fadeOut(speed);
    }
    return el;
}

window.isActive = true;

window.onfocus = function () {
  isActive = true;
};

window.onblur = function () {
  isActive = false;
};
