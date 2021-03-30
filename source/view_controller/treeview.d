module konsola_operatorska.view_controller.treeview;

import konsola_operatorska.station;
import konsola_operatorska.model.stations;
import konsola_operatorska.utils : delegateToObjectDelegate, delegateToCallbackTuple;

import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.TreeModelIF;
import gtk.TreeModelT;
import gtkd.Implement;

import gtk.StyleContext;
import gtk.Widget;

import gtk.CellRenderer;
import gtk.CellRendererText;
import gtk.CellRendererPixbuf;
import gtk.CellRendererProgress;
import gtk.ListStore;
import gtk.TreeIter;

import std.stdio;
import std.meta;
import std.conv;

enum Column
{
    Id = 0,
    Name = 1,
    Type = 2,
    Serial = 3,
    Strength = 4,
    BatteryLevel = 5,
    WorkingMode = 6
}

/// Pseudo model for using the station model with GTK's tree view
class StationListStore : ListStore
{
    StationModel model;

    this(StationModel model)
    {
        // Mapping of station fields to GTypes
        // dfmt off
        super([
                GType.INT, //Id
		GType.STRING, //Name
		GType.INT, //Type - enum as an int
		GType.STRING, //SerialNumber
		GType.INT, //Strength - Times 10, to get strength as a percentage
                GType.INT, //BatteryLevel
		GType.STRING, //WorkingMode
        ]);

	this.model = model;

	foreach(station; model.stations.values()) {
	    this.onStationAdded(station);
	}

	model.StationAdded.connect(&this.onStationAdded);
    }

    void onStationAdded(StationWithEvents stationEvent) {
	auto iter = this.createIter();
	setStationRow(iter,stationEvent.station);

	stationEvent.Changed.connect(delegateToObjectDelegate({
		this.setStationRow(iter, stationEvent.station);
	    }));
	stationEvent.Removed.connect(delegateToObjectDelegate({
		this.remove(iter);
	    }));
    }

    void setStationRow(TreeIter iter, Station bs) {
		setValue(iter, Column.Id, bs.id);
		setValue(iter, Column.Name, bs.name);
		setValue(iter, Column.Type, bs.type);
		setValue(iter, Column.Serial, bs.serialNumber);
		setValue(iter, Column.Strength, bs.strength*10); // Times 10, to get strength as a percentage
		setValue(iter, Column.BatteryLevel, bs.batteryLevel);
		setValue(iter, Column.WorkingMode, bs.workingMode.to!string);

    }

}

class StationTextColumn : TreeViewColumn
{
	CellRendererText cellRendererText;
	string attributeType = "text";

	this(string columnTitle, Column col)
	{
		cellRendererText = new CellRendererText();
		
		super(columnTitle, cellRendererText, attributeType, col);
		setSortColumnId(col);
		this.setReorderable(true);
		this.setResizable(true);
	} 
} 

extern(C) {
    /// Function passed to gtk in a TreeViewColumn to convert the StationType enum into a CellRendererPixbuf 
    void stationTypeCellDataFunc(GtkTreeViewColumn* col_c, GtkCellRenderer* ren_c, GtkTreeModel* model_c, GtkTreeIter* iter_c, void* data) { 
		    // Convert arguments from C types to D types
		    auto ren = new CellRenderer(ren_c);
		    auto model = new ListStore(cast(GtkListStore*)model_c);
		    auto iter = new TreeIter(iter_c);

		    Value val;
		    model.getValue(iter, 2, val);
		    StationType bs_type = cast(StationType)val.getInt();

	        	string typeIconName;
	        	final switch(bs_type) {
	        	    case StationType.Portable:
				typeIconName = "mobile-symbolic";
				break;
	        	    case StationType.Car:
	        		typeIconName = "truck-symbolic";
	        		break;
	        	    case StationType.BaseStation:
	        		typeIconName = "broadcast-tower-symbolic";
				break;
	        	}
		    ren.setProperty("icon-name", typeIconName);
	}
}

class StationTypeCol: TreeViewColumn
{
    CellRendererPixbuf cellRenderer;
    Column col = Column.Type;
    string columnName = "Type";
    this()
    {
	cellRenderer = new CellRendererPixbuf();
	super(columnName, cellRenderer, "icon-name", col); 
	cellRenderer.setProperty("icon-name", "broadcast-tower");

	this.setSortColumnId(col);
	this.setReorderable(true);

	this.setResizable(false);

	this.setCellDataFunc(cellRenderer, &stationTypeCellDataFunc, null, null);
    }
}

class BatteryLevelCol: TreeViewColumn
{
    CellRendererProgress cellRenderer;
    this()
    {
	cellRenderer = new CellRendererProgress();

	super("Battery Level", cellRenderer, "value", Column.BatteryLevel); 

	this.setReorderable(true);
	this.setSortColumnId(Column.BatteryLevel);

	this.setResizable(false);
    }
}

class SignalStrengthCol: TreeViewColumn
{
    CellRendererProgress cellRenderer;
    this()
    {
	cellRenderer = new CellRendererProgress();

	super("Signal", cellRenderer, "value", Column.Strength); 

	this.setReorderable(true);
	this.setSortColumnId(Column.Strength);

	this.setResizable(false);
    }
}

class StationTreeView : TreeView {
    StationListStore listStore;
    this(StationModel model) {
	appendColumn(new StationTextColumn("ID", Column.Id));
	appendColumn(new StationTextColumn("Name", Column.Name));
	appendColumn(new StationTypeCol());
	appendColumn(new StationTextColumn("Serial", Column.Serial));
	appendColumn(new SignalStrengthCol());
	appendColumn(new BatteryLevelCol());
	appendColumn(new StationTextColumn("Working Mode", Column.WorkingMode));
	
	auto listStore = new StationListStore(model);
	this.listStore = listStore;

	setModel(listStore);
    }
}