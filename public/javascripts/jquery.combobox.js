(function($) {
    // widget for pagination
    $.widget("ui.combobox", {
        options:{
            // maximum custom value
            max_value: 1000,
            // executed at the beginning of _create method
            beforeCreate: function(){},
            afterCreate: function(){},
            // function that is executed when selected value changes
            onChange: function(){},
            position: 'top'
        },
        _create: function() {
            this.options.beforeCreate();
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
                position: { my: "left "+self.options.position, at: "left "+self.options.position, collision: "none" },
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
                    self.options.onChange(ui, event);
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
                            if(self.options.max_value !== undefined && (isNaN(new_value) || new_value >= self.options.max_value)){
                                $(this).val(initial_value)
                            }
                            else if(self.options.allow_custom_values === false){
                                return;
                            }
                        }
                        self.options.onChange(ui.item !== null ? ui : $(this).val(), event);
                    }
                },
                // create
                create: function(event, ui){
                    self.options.afterCreate();
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