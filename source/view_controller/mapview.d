module konsola_operatorska.view_controller.map;
import konsola_operatorska.model.stations;
import konsola_operatorska.station;

import gtk.Image;

import shumate.View;
import shumate.Scale;
import shumate.Marker;
import shumate.MapLayer;
import shumate.MarkerLayer;
import shumate.MapSourceFactory;

import std.stdio;

class StationMarker : Marker {
    StationWithEvents station;
    this(StationWithEvents station)
    {
        super();

        Image image = new Image();
        image.setFromIconName(stationTypeToIconName(station.type));
        this.setChild(image);

        this.station = station;
        this.setLocation(station.position.lat, station.position.lon);
    }

    void onStationChanged(StationWithEvents station) {

    }

    void onStationRemoved() {

    }
}

class Mapview : View
{
    StationModel model;
    MarkerLayer markerLayer;
    this(StationModel model)
    {
        super();
        this.model = model;

        auto viewport = this.getViewport();
        auto sourceFactory = MapSourceFactory.dupDefault();


        auto mapSource = sourceFactory.createCachedSource("osm-mapnik");

        viewport.setReferenceMapSource(mapSource);
        viewport.setMinZoomLevel(2);

        auto mapLayer = new MapLayer(mapSource, viewport);
        this.addLayer(mapLayer);

        this.markerLayer = new MarkerLayer(viewport);
        this.addLayer(markerLayer);

	model.StationAdded.connect(&this.onStationAdded);
    }

    void onStationAdded(StationWithEvents station) {
        auto marker = new StationMarker(station);
        this.markerLayer.addMarker(marker);
    }
}
