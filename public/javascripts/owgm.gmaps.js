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

/*** Google Maps ***/
var gmaps = {

    mapDiv: '#gmap_index',
    mapDivSingle: '#gmap_show',
    mapLoadingDiv: '#map_loading',
    mapToggle: '#map_toggle',
    mapContainer: '#map_container',
    accessPointTemplate: '#access_point_infowindow_templ',
    clusterTemplate: '#cluster_infowindow_templ',
    accessPointClusterTemplate: '#access_points_infowindow_templ',
    markerShadow: 'shadow.png',
    map: undefined, // will be defined in drawGoogleMap
    mgr: undefined, // will be defined in drawMarkers
    bnds: undefined, // will be defined in as LatLngBounds
    latSelector: 'data-lat',
    lngSelector: 'data-lng',
    singleAccessPointIcon: '#hs_icon',
    min_zoom: 0,
    cluster_till_zoom: 12,
    max_zoom: 19,
    accessPoints: [],
    clusters: [],
    accessPointsClustered: [],

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
        // if mapContainer is not visible don't load 
        if($(gmaps.mapContainer).is(':visible') && owgm.exists(gmaps.mapDiv)) {
            $(gmaps.mapLoadingDiv).show();
            gmaps.bnds = new google.maps.LatLngBounds();
            // accessPoints (many) index view. Fetch data to draw
            // by parsing JSON data retrieved from the save view.
            // accessPoints are drawn via MarkerManager v3
            var map_div_id = $(gmaps.mapDiv).attr('id');
            gmaps.map = new google.maps.Map(document.getElementById(map_div_id), $.extend(gmaps.opts, {
                zoom: 7,
                center: gmaps.getCoords(0,0)
            }));
            var listener = google.maps.event.addListener(gmaps.map, 'bounds_changed', function(){
                gmaps.fetchMarkers();
                $(gmaps.mapDiv).ajaxStop(gmaps.drawMarkers);
                google.maps.event.removeListener(listener);
            });
        } else if (owgm.exists(gmaps.mapDivSingle)) {
            // accessPoint (just one) show view. Fetch data to draw
            // by parsing directly html tag attributes.
            var map_div_id = $(gmaps.mapDivSingle).attr('id');
            var access_point_coords = gmaps.getCoords($(gmaps.mapDivSingle).attr(gmaps.latSelector), $(gmaps.mapDivSingle).attr(gmaps.lngSelector));
            gmaps.map = new google.maps.Map(document.getElementById(map_div_id), $.extend(gmaps.opts, {
                zoom: 18,
                center: access_point_coords,
                draggable: true,
                navigationControlOptions: {style: google.maps.NavigationControlStyle.SMALL},
                disableDoubleClickZoom: false,
                keyboardShortcuts: false
            }));
            var _marker = new google.maps.Marker({
                position: access_point_coords,
                map: gmaps.map,
                icon: gmaps.gIcon($(gmaps.singleAccessPointIcon).attr('src')),
                shadow: gmaps.gShadow($(gmaps.singleAccessPointIcon).attr('src'))
            });
            gmaps.tmpMarker = _marker;
        }
    },

    fitMarkers: function() {
        gmaps.map.fitBounds(gmaps.bnds);
        if (gmaps.map.getZoom() > gmaps.cluster_till_zoom) {
            gmaps.map.setZoom(gmaps.cluster_till_zoom);
        }
    },

    drawMarkers: function() {
        if (! gmaps.mgr) {
            gmaps.mgr = new MarkerManager(gmaps.map);
            google.maps.event.addListener(gmaps.mgr, 'loaded', function(){
                gmaps.mgr.addMarkers(gmaps.accessPoints, gmaps.min_zoom, gmaps.max_zoom);
                gmaps.mgr.addMarkers(gmaps.clusters, gmaps.min_zoom, gmaps.cluster_till_zoom);
                gmaps.mgr.addMarkers(gmaps.accessPointsClustered, gmaps.cluster_till_zoom+1, gmaps.max_zoom);
                gmaps.mgr.refresh();
                $(gmaps.mapLoadingDiv).fadeOut('slow');
            });
            gmaps.fitMarkers();
        }
    },

    fetchMarkers: function() {
        $.getJSON(location.href+'?simple=true', function(markers){
            $.each(markers, function(){
                var marker_container;
                if (this.access_point) {
                    marker_container = new google.maps.Marker({
                        position: gmaps.getCoords(this.access_point.lat, this.access_point.lng),
                        icon: gmaps.gIcon(this.access_point.icon),
                        shadow: gmaps.gShadow(this.access_point.icon)
                    });
                    gmaps.accessPoints.push(marker_container);
                    gmaps.addInfoWindow(marker_container, gmaps.buildAccessPointInfo(this.access_point));
                    gmaps.bnds.extend(marker_container.getPosition());
                } else if (this.cluster) {
                    marker_container = new google.maps.Marker({
                        position: gmaps.getCoords(this.cluster.lat, this.cluster.lng),
                        icon: gmaps.gIcon(this.cluster.icon),
                        shadow: gmaps.gShadow(this.cluster.icon)
                    });
                    gmaps.clusters.push(marker_container);
                    gmaps.addInfoWindow(marker_container, gmaps.buildClusterInfo(this.cluster));
                    gmaps.bnds.extend(marker_container.getPosition());
                    $.each(this.cluster.access_points, function(){
                        marker_container = new google.maps.Marker({
                            position: gmaps.getCoords(this.access_point.lat, this.access_point.lng),
                            icon: gmaps.gIcon(this.access_point.icon),
                            shadow: gmaps.gShadow(this.access_point.icon)
                        });
                        gmaps.accessPointsClustered.push(marker_container);
                        gmaps.addInfoWindow(marker_container, gmaps.buildAccessPointInfo(this.access_point));
                    });
                }
            });
        });
    },

    gIcon: function(src) {
        return new google.maps.MarkerImage(src, new google.maps.Size(32.0, 37.0), new google.maps.Point(0, 0), new google.maps.Point(16.0, 18.0));
    },

    gShadow: function(icon_src) {
        var _shadow_src = icon_src.split('/');
        _shadow_src[_shadow_src.length-1] = gmaps.markerShadow;
        return new google.maps.MarkerImage(_shadow_src.join('/'), new google.maps.Size(51.0, 37.0), new google.maps.Point(0, 0), new google.maps.Point(16.0, 18.0));
    },

    addInfoWindow: function(marker, contentString) {
        var infowindow = new google.maps.InfoWindow({
            content: contentString
        });
        google.maps.event.addListener(marker, 'click', function() {
            infowindow.open(gmaps.map,marker);
        });
    },

    buildAccessPointInfo: function(access_point) {
        var _content = $(gmaps.accessPointTemplate).clone().html();
        _content = _content.replace(/__hostname__/, access_point.hostname);
        _content = _content.replace(/__address__/, access_point.address);
        _content = _content.replace(/__city__/, access_point.city);
        _content = _content.replace(/__url__/, access_point.url);
        _content = _content.replace(/__icon__/, access_point.icon);
        return _content;
    },

    buildClusterInfo: function(cluster) {
        var _content = $(gmaps.clusterTemplate).clone().html();
        var _access_points, _access_point;
        _access_points = "";

        $.each(cluster.access_points, function(){
            _access_point = $(gmaps.accessPointClusterTemplate).clone().html();
            _access_point = _access_point.replace(/__icon__/, this.access_point.icon);
            _access_point = _access_point.replace(/__hostname__/, this.access_point.hostname);
            _access_point = _access_point.replace(/__url__/, this.access_point.url);
            _access_points += _access_point;
        });

        _content = _content.replace(/__access_points__/, _access_points);
        return _content;
    },
    
    loadMarkersFromJSON: function(url){
        // get AP data
        $.getJSON(url).done(function(json, status, xhr){
            // init empty container
            gmaps.accessPoints = [];
            gmaps.infoWindow = new google.maps.InfoWindow({});
            // loop over results
            for(var i=0,length=json.length; i<length; i++){
                var ap = json[i].access_point,
                    // gmap marker
                    marker = new google.maps.Marker({
                            position: new google.maps.LatLng(ap.lat, ap.lng),
                            //map: gmaps.map,
                            icon: gmaps.gIcon(ap.icon),
                            shadow: gmaps.gShadow(ap.icon),
                            // store extra info
                            name: ap.hostname,
                            url: ap.url
                    });
                gmaps.accessPoints[i] = marker;
                // bind info window on click
                google.maps.event.addListener(gmaps.accessPoints[i], 'click', function() {
                    // close any open info windows
                    gmaps.infoWindow.close();
                    // set content (linked name)
                    gmaps.infoWindow.setContent('<a href="'+this.url+'">'+this.name+'</a>')
                    // open
                    gmaps.infoWindow.open(gmaps.map, this);
                });
            }
            // remove initial marker (there are two overlapping accessPoints)
            gmaps.tmpMarker.setMap(null);
            
            gmaps.markerCluster = new MarkerClusterer(gmaps.map, gmaps.accessPoints, {
                gridSize: 23,
                maxZoom: 18
            });
        });
    }
}
