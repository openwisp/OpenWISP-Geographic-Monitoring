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
    owgm.paginator();
    owgm.initNotice();
    owgm.initMainMenu();
    owgm.initDynamicColumns();
    owgm.initTooltip();
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
            $("#combobox select").combobox();    
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
        // convert data array to JSON string
        json_data = JSON.stringify(data);
        // POST the JSON string to Rails
        $.ajax({
            type: 'post',
            url: export_url,
            data: json_data,
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
    
    initBatchGroupSelection: function(post_url){
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
        
        var openGroupBatchSelection = function(){
            // at least one ap must be selected
            if($("#access_points tr.ui-selected").length < 1){
                alert($('.batch-change-group').attr('data-fail-message'));
            }
            else{
                owgm.openGroupSelection({
                    'url': $('.batch-change-group').attr('href'),
                    'afterSelect': function(){
                        owgm.toggleLoading();
                        // this function changes the group in batch
                        changeGroupBatch($(this).attr('data-group-id'));
                        owgm.toggleOverlay(function(){
                            // close call back of overlay
                            owgm.toggleLoading();
                            $('#select-group').remove();
                        });
                    }
                });
            }
        }
        
        var changeGroupBatch = function(group_id){
            var selected_access_points_id = [],
                selected_access_points = $("#access_points tr.ui-selected");
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
                data: JSON.stringify({ "group_id": group_id, "access_points": selected_access_points_id })
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
                        $('#access_points tr[data-ap-id='+$(e).attr('data-ap-id')+']').addClass('ui-selected');
                    });
                });
            });
        }
        
        $('.batch-change-group').click(function(e){
            e.preventDefault();
            openGroupBatchSelection();
        });
        
        // keyboard shortcuts
        $(document).keydown(function(e){
            // ESC: deselect all the access points
            if(e.keyCode == 27){
                $("#access_points tr.ui-selected").removeClass('ui-selected');
            }
            // CTRL + A: select all the access points
            else if(e.ctrlKey && e.keyCode == 65){
                e.preventDefault();
                $("#access_points tr").addClass('ui-selected');
            }
            // CTRL + G: open group selection
            else if(e.ctrlKey && e.keyCode == 71){
                e.preventDefault();
                openGroupBatchSelection();
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
        $('.toggle-favourite').live('click',function(e){
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
