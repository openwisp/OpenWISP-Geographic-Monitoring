/*** Google Maps ***/
var gmaps = {

    mapDiv: '#gmap_index',
    mapDivSingle: '#gmap_show',
    mapLoadingDiv: '#map_loading',
    hotspotTemplate: '#hotspot_marker_template',
    clusterTemplate: '#cluster_marker_template',
    map: undefined, // will be defined in drawGoogleMap
    mgr: undefined, // will be defined in drawMarkers
    latSelector: 'data-lat',
    lngSelector: 'data-lng',
    singleHotspotIcon: '#hs_icon',
    min_zoom: 0,
    cluster_till_zoom: 12,
    max_zoom: 19,
    hotspots: [],
    clusters: [],
    hotspots_clustered: [],

    /* Google Maps Specific Configuration Variables */
    opts: {
        scrollwheel: true,
        mapTypeId: 'roadmap'
    },

    /*** Mapping Functions ***/
    getCoords: function (lat, lng) {
        return new google.maps.LatLng(lat, lng)
    },

    drawGoogleMap: function() {
        if(owgm.exists(gmaps.mapDiv)) {
            $(gmaps.mapLoadingDiv).show();
            // Hotspots (many) index view. Fetch data to draw
            // by parsing JSON data retrieved from the save view.
            // Hotspots are drawn via MarkerManager v3
            var map_div_id = $(gmaps.mapDiv).attr('id');
            gmaps.map = new google.maps.Map(document.getElementById(map_div_id), $.extend(gmaps.opts, {
                zoom: 7,
                center: gmaps.getCoords($(gmaps.mapDiv).attr(gmaps.latSelector), $(gmaps.mapDiv).attr(gmaps.lngSelector))
            }));
            var listener = google.maps.event.addListener(gmaps.map, 'bounds_changed', function(){
                gmaps.fetchMarkers();
                $(gmaps.mapDiv).ajaxStop(gmaps.drawMarkers);
                google.maps.event.removeListener(listener);
            });
        } else if (owgm.exists(gmaps.mapDivSingle)) {
            // Hotspot (just one) show view. Fetch data to draw
            // by parsing directly html tag attributes.
            var map_div_id = $(gmaps.mapDivSingle).attr('id');
            var hotspot_coords = gmaps.getCoords($(gmaps.mapDivSingle).attr(gmaps.latSelector), $(gmaps.mapDivSingle).attr(gmaps.lngSelector));
            gmaps.map = new google.maps.Map(document.getElementById(map_div_id), $.extend(gmaps.opts, {
                zoom: 13,
                center: hotspot_coords,
                draggable: false,
                navigationControlOptions: {style: google.maps.NavigationControlStyle.SMALL},
                disableDoubleClickZoom: true,
                keyboardShortcuts: false
            }));
            new google.maps.Marker({
                position: hotspot_coords,
                map: gmaps.map,
                icon: $(gmaps.singleHotspotIcon).attr('src')
            });
        }
    },

    drawMarkers: function() {
        if (! gmaps.mgr) {
            gmaps.mgr = new MarkerManager(gmaps.map);
            google.maps.event.addListener(gmaps.mgr, 'loaded', function(){
                gmaps.mgr.addMarkers(gmaps.hotspots, gmaps.min_zoom, gmaps.max_zoom);
                gmaps.mgr.addMarkers(gmaps.clusters, gmaps.min_zoom, gmaps.cluster_till_zoom);
                gmaps.mgr.addMarkers(gmaps.hotspots_clustered, gmaps.cluster_till_zoom+1, gmaps.max_zoom);
                gmaps.mgr.refresh();
                $(gmaps.mapLoadingDiv).fadeOut('slow');
            });
        }
    },

    fetchMarkers: function() {
        $.getJSON(location.href, function(markers){
            $.each(markers, function(){
                var marker_container;
                if (this.hotspot) {
                    marker_container = new google.maps.Marker({
                        position: gmaps.getCoords(this.hotspot.lat, this.hotspot.lng),
                        icon: this.hotspot.icon
                    });
                    gmaps.hotspots.push(marker_container);
                    gmaps.addInfoWindow(marker_container, gmaps.buildHotspotInfo(this.hotspot));
                } else if (this.cluster) {
                    marker_container = new google.maps.Marker({
                        position: gmaps.getCoords(this.cluster.lat, this.cluster.lng),
                        icon: this.cluster.icon
                    });
                    gmaps.clusters.push(marker_container);
                    gmaps.addInfoWindow(marker_container, gmaps.buildClusterInfo(this.cluster));
                    $.each(this.cluster.hotspots, function(){
                        marker_container = new google.maps.Marker({
                            position: gmaps.getCoords(this.hotspot.lat, this.hotspot.lng),
                            icon: this.hotspot.icon
                        });
                        gmaps.hotspots_clustered.push(marker_container);
                        gmaps.addInfoWindow(marker_container, gmaps.buildHotspotInfo(this.hotspot));
                    });
                }
            });
        });
    },

    addInfoWindow: function(marker, contentString) {
        var infowindow = new google.maps.InfoWindow({
            content: contentString
        });
        google.maps.event.addListener(marker, 'click', function() {
            infowindow.open(gmaps.map,marker);
        });
    },

    buildHotspotInfo: function(hotspot) {
        var _content = $(gmaps.hotspotTemplate).clone();
        _content.find(".hostname").html(hotspot.hostname);
        _content.find(".city").html(hotspot.city);
        _content.find(".address").html(hotspot.address);
        _content.find(".url").attr('href', hotspot.url);
        return _content.html();
    },

    buildClusterInfo: function(cluster) {
        var _content = $(gmaps.clusterTemplate).clone();
        var _hotspot = _content.find(".one_hotspot").clone();
        _content.find(".one_hotspot").remove();

        $.each(cluster.hotspots, function(){
            _hotspot.find(".icon").attr('src', this.hotspot.icon);
            _hotspot.find(".hostname").html(this.hotspot.hostname);
            _hotspot.find(".url").attr('href', this.hotspot.url);
            _hotspot.clone().appendTo(_content.find(".hotspots"));
        });
        return _content.html();
    }
}
