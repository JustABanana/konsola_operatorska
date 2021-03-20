module konsola_operatorska.mapview;

import std.conv: to;
import std.algorithm;
import std.math;
import std.stdio;

import gdkpixbuf.Pixbuf;
import gdkpixbuf.PixbufLoader;
import cairo.Context;
import cairo.ImageSurface;
import cairo.Pattern;
import gobject.ObjectG;
import gtkd.Implement;
import gobject.Value;
import rsvg.Handle;

import osm_gps_map.Map;
import osm_gps_map.MapOsd;
import osm_gps_map.MapImage;
import osm_gps_map.MapPoint;
import osm_gps_map.MapLayerIF;
import osm_gps_map.MapLayerT;
import osm_gps_map.c.types;

import konsola_operatorska.basestation;
import konsola_operatorska.basestation_model;


Handle tower;

shared static this() {
	ubyte[] tower_svg = cast(ubyte[])import("assets/broadcast-tower-solid.svg");
	tower = new Handle(tower_svg);
}


class StationMap: Map {
	BaseStationModel model;
	this(BaseStationModel model) {
		super();
		this.model = model;
		this.mapSource = OsmGpsMapSource_t.OPENSTREETMAP;

		auto stationsLayer = new BaseStationsLayer();
		this.layerAdd(stationsLayer);

		this.setSizeRequest(300,500);
	}
}

class BaseStationsLayer: ObjectG, MapLayerIF {
	static STATION_ICON_WIDTH_IN_METERS = 5;
	mixin ImplementInterface!(GObject,OsmGpsMapLayerIface);
	mixin MapLayerT!(OsmGpsMap);

	ImageSurface sf;
	MapPoint mp;
	Pattern pt;

	
	this() {
		super(getType(), null);
		this.mp = new MapPoint(50.0656, 19.9602);

		RsvgDimensionData* data = new RsvgDimensionData;
		tower.getDimensions(*data);
		this.sf = ImageSurface.create(CairoFormat.ARGB32,data.width,data.height);
		Context ctx = Context.create(sf);
		tower.renderCairo(ctx);
		pt = Pattern.createForSurface(sf);
	}

	OsmGpsMapLayer* getMapLayerStruct(bool transferOwnership = false) {
		return cast(OsmGpsMapLayer*)getObjectGStruct(transferOwnership);
	}

	public bool busy() {
		// We always block when rendering so we're never busy
		return false;
	}

	/**
	 * Handle button event
	 *
	 * Params:
	 *     map = a #OsmGpsMap widget
	 *     event = a #GdkEventButton event
	 *
	 * Returns: whether even had been handled
	 *
	 * Since: 0.6.0
	 */
	public bool buttonPress(Map map, GdkEventButton* event) {
		return false;
	}

	float getScale(Map map) {
		int distanceFromMaxZoom = (map.zoom-map.maxZoom)-map.minZoom;

		// Every zoom level increases the scale of the map by 2 times
		float scale = pow(2.0, distanceFromMaxZoom);
		if(distanceFromMaxZoom < -10) {
			scale = 0.0;
		}
		return scale;
	}

	/**
	 * Draw layer on map
	 *
	 * Params:
	 *     map = a #OsmGpsMap widget
	 *     cr = a cairo context to draw to
	 *
	 * Since: 0.6.0
	 */
	public void draw(Map map, Context cr) {
		RsvgDimensionData* data = new RsvgDimensionData;
		tower.getDimensions(*data);

		int pixel_x;
		int pixel_y;
		map.convertGeographicToScreen(mp,pixel_x, pixel_y);
		cr.translate(pixel_x, pixel_y);

		RsvgDimensionData* towerDimensions = new RsvgDimensionData;
		tower.getDimensions(*towerDimensions);


		double scale = getScale(map);
		if(scale != 0.0) {
			cr.scale(scale,scale);
			cr.setSource(pt);
		}
		cr.paint();
	}

	/**
	 * Render layer on map
	 *
	 * Params:
	 *     map = a #OsmGpsMap widget
	 *
	 * Since: 0.6.0
	 */
	public void render(Map map) {
		Context cr = Context.create(sf);
		float metersPerPx = map.getScale();

		RsvgDimensionData* towerDimensions = new RsvgDimensionData;
		tower.getDimensions(*towerDimensions);
	}
}
