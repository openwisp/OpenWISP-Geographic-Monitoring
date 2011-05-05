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
                Highcharts.setOptions({lang: this.lang});
            }
        });
    }
};

