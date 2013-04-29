(function($) {
    // widget for pagination
    $.widget("ui.combobox", {
        options:{
            // links to edit per_page querystring value
            links: '#access_points_paginate .pagination a',
            form: '#access_points_quicksearch form',
            // maximum custom value
            max_value: 100,
            // function that is executed when selected value changes
            onChange: function(val){
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
                    // trigger click
                    $('#access_points_paginate .page a').eq(0).trigger('click');
                });
                // if form is defined
                if(this.form){
                    // update action
                    updateUrl($(this.form), 'action', val);
                }
            }    
        },
        _create: function() {
            var input,
            self = this,
            select = this.element.hide(),
            selected = select.children(":selected"),
            initial_value = selected.val() ? selected.text() : "",
            wrapper = this.wrapper = $("<form>")
            .addClass("ui-combobox")
            .insertAfter(select);
    
            input = $("<input>")
            .appendTo(wrapper)
            .val(initial_value)
            .addClass("ui-state-default ui-combobox-input")
            .autocomplete({
                delay: 0,
                minLength: 0,
                position: { my: "left bottom", at: "left bottom", collision: "none" },
                source: function(request, response) {
                    var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
                    response(select.children("option").map(function() {
                        var text = $(this).text();
                        if (this.value && (!request.term || matcher.test(text)))
                            return {
                                label: text.replace(
                                    new RegExp(
                                        "(?![^&;]+;)(?!<[^<>]*)(" +
                                        $.ui.autocomplete.escapeRegex(request.term) +
                                        ")(?![^<>]*>)(?![^&;]+;)", "gi"
                                   ), "<strong>$1</strong>"),
                                value: text,
                                option: this
                            };
                    }));
                },
                select: function(event, ui) {
                    ui.item.option.selected = true;
                    self._trigger("selected", event, {
                        item: ui.item.option
                    });
                    self.options.onChange(ui.item.value)
                },
                // when users inserts a value
                change: function(event, ui) {
                    if (!ui.item) {
                        var matcher = new RegExp("^" + $.ui.autocomplete.escapeRegex($(this).val()) + "$", "i"),
                            valid = false;
                        // if it matches one of the options
                        select.children("option").each(function() {
                            if ($(this).text().match(matcher)) {
                                // trigger selection
                                this.selected = valid = true;
                            }
                        });
                        // if user inserts a custom value
                        if (!valid) {				    
                            var new_value = parseInt($(this).val());
                            // check that custom value is integer and that is not greater than maximum value
                            if(isNaN(new_value) || new_value >= self.options.max_value){
                                $(this).val(initial_value)
                            }
                        }
                        self.options.onChange($(this).val())
                    }
                }
            })
            .addClass("ui-widget ui-widget-content ui-corner-left");
    
            input.data("autocomplete")._renderItem = function(ul, item) {
                return $("<li></li>")
                .data("item.autocomplete", item)
                .append("<a>" + item.label + "</a>")
                .appendTo(ul);
            };
            // if pressing enter in the input
            wrapper.submit(function(e){
                // prevent default form behaviour
                e.preventDefault();
                // trigger action
                input.trigger('blur');
            });
    
            $("<a>")
            .attr("tabIndex", -1)
            .attr("title", "Show All Items")
            .appendTo(wrapper)
            .button({
                icons: {
                    primary: "ui-icon-triangle-1-s"
                },
                text: false
            })
            .removeClass("ui-corner-all")
            .addClass("ui-corner-right ui-combobox-toggle")
            .click(function() {
                // close if already visible
                if (input.autocomplete("widget").is(":visible")) {
                    input.autocomplete("close");
                    return;
                }
    
                // work around a bug (likely same cause as #5265)
                $(this).blur();
    
                // pass empty string as value to search for, displaying all results
                input.autocomplete("search", "");
                input.focus();
            });
        },
    
        destroy: function() {
            this.wrapper.remove();
            this.element.show();
            $.Widget.prototype.destroy.call(this);
        }
    });
})(jQuery);