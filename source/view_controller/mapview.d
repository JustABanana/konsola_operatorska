module konsola_operatorska.view_controller.map;
import konsola_operatorska.model.stations;
import konsola_operatorska.station;

import gtk.Image;

import gtkd.Implement;

import shumate.View;
import shumate.Scale;
import shumate.Marker;
import shumate.MapLayer;
import shumate.MapSourceChain;
import shumate.MarkerLayer;
import shumate.MapSourceFactory;

import std.conv;
import std.stdio;
import std.typecons;

class StationMarker : Marker
{
    Station station;
    Image img;

    this(Station station)
    {
        super();

        this.img = new Image();
        this.img.setIconSize(GtkIconSize.LARGE);
        this.setChild(this.img);

        this.updateStation(station);
    }

    void updateStation(Station station)
    {
        this.setLocation(station.position.lat, station.position.lon);

        this.img.setFromIconName(stationTypeToIconName(station.type));

        auto context = this.getStyleContext();
        foreach (i; 0 .. 10)
        {
            context.removeClass("station-status-" ~ i.to!string);
        }
        context.addClass("station-status-" ~ (station.calcStationHealth() / 10).to!string);
    }

    void setSelected(bool selected)
    {
        auto context = this.getStyleContext();
        if (selected)
            context.addClass("selected-station");
        else
            context.removeClass("selected-station");
    }
}

class Mapview : View
{
    StationModel model;
    MarkerLayer markerLayer;
    StationMarker[int] idToMarker;

    Nullable!StationMarker currentSelection;

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
        model.SelectionChanged.connect(&this.setSelection);
    }

    void onStationAdded(Station station)
    {
        auto marker = new StationMarker(station);
        this.idToMarker[station.id] = marker;

        this.markerLayer.addMarker(marker);
    }

    void onStationChanged(Station station)
    {
        this.idToMarker[station.id].updateStation(station);
    }

    void onStationRemoved(Station station)
    {
        auto marker = this.idToMarker[station.id];
        this.markerLayer.removeMarker(marker);
        this.idToMarker.remove(station.id);
    }

    void setSelection(Nullable!Station selection)
    {
        if (!this.currentSelection.isNull)
        {
            currentSelection.get().setSelected(false);
            this.currentSelection.nullify();
        }
        if (!selection.isNull)
        {
            this.currentSelection = this.idToMarker[selection.get().id];
            this.currentSelection.get().setSelected(true);

            Position pos = selection.get().position;
            this.goTo(pos.lat, pos.lon);
        }
    }
}
