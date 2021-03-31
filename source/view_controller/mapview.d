module konsola_operatorska.view_controller.map;
import konsola_operatorska.model.stations;
import konsola_operatorska.station;

import gtk.Image;

import shumate.View;
import shumate.Scale;
import shumate.Marker;
import shumate.MapLayer;
import shumate.MapSourceChain;
import shumate.MarkerLayer;
import shumate.MapSourceFactory;

import std.stdio;

class StationMarker : Marker {
    Station station;
    StationType type;
    Image img;
    this(Station station)
    {
        super();

        this.img = new Image();
        this.setChild(this.img);

        this.updateStation(station);
    }

    void updateStation(Station station) {
        this.setLocation(station.position.lat, station.position.lon);
        this.img.setFromIconName(stationTypeToIconName(station.type));
    }
}

class Mapview : View
{
    StationModel model;
    MarkerLayer markerLayer;
    StationMarker[int] idToMarker;
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
        model.StationChanged.connect(&this.onStationChanged);
    }

    void onStationAdded(Station station) {
        auto marker = new StationMarker(station);
        this.idToMarker[station.id] = marker;

        this.markerLayer.addMarker(marker);
    }

    void onStationChanged(Station station) {
        this.idToMarker[station.id].updateStation(station);
    }

    void onStationRemoved(Station station) {
        auto marker = this.idToMarker[station.id];
        this.markerLayer.removeMarker(marker);
        this.idToMarker.remove(station.id);
    }
}
