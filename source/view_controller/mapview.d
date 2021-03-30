module konsola_operatorska.view_controller.map;
import konsola_operatorska.model.stations;
import shumate.View;
import shumate.Scale;
import shumate.MapLayer;
import shumate.MapSourceFactory;

import std.stdio;

class Mapview : View
{
    StationModel model;
    this(StationModel model)
    {
        super();
        this.model = model;

        auto viewport = this.getViewport();
        auto sourceFactory = MapSourceFactory.dupDefault();

        auto mapSource = sourceFactory.createCachedSource("osm-mapnik");
        mapSource.setNextSource(null);
        viewport.setReferenceMapSource(mapSource);
        viewport.setMinZoomLevel(2);

        auto layer = new MapLayer(mapSource, viewport);
        this.setVexpand(true);

        this.addLayer(layer);
    }
}
