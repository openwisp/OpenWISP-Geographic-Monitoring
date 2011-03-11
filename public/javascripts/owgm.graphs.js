var graphs = {
    // Private functions and variables
    _plotted: [],
    init: function(_graph) {
        $(document).ready(function() {
            graphs._plotted.push(new Highcharts.Chart(_graph));
        });
    },

    daysAgo: function(days) {
        return new Date().setDate(graphs.today().getDate()-days);
    },

    today: function() {
        return new Date();
    }
};
