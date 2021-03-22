module konsola_operatorska.basestation_treeview;

import konsola_operatorska.basestation;
import konsola_operatorska.basestation_model;
import konsola_operatorska.utils : delegateToObjectDelegate, delegateToCallbackTuple;

import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.TreeModel;

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

/// Pseudo model for using the basestation_model with GTK's tree view
class BaseStationListStore : ListStore
{
    BaseStationModel model;

    this(BaseStationModel model)
    {
        // Mapping of basestation fields to GTypes
        // dfmt off
        super([
                GType.INT, //Id
		GType.STRING, //Name
		GType.INT, //Type - enum as an int
		GType.STRING, //SerialNumber
		GType.INT, //Strength
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
	setBaseStationRow(iter,stationEvent.station);

	stationEvent.Changed.connect(delegateToObjectDelegate({
		this.setBaseStationRow(iter, stationEvent.station);
	    }));
	stationEvent.Removed.connect(delegateToObjectDelegate({
		this.remove(iter);
	    }));
    }

    void setBaseStationRow(TreeIter iter, BaseStation bs) {
		setValue(iter, Column.Id, bs.id);
		setValue(iter, Column.Name, bs.name);
		setValue(iter, Column.Type, bs.type);
		setValue(iter, Column.Serial, bs.serialNumber);
		setValue(iter, Column.Strength, bs.strength);
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
		    auto model = new TreeModel(model_c);
		    auto iter = new TreeIter(iter_c);

		    StationType bs_type = cast(StationType)model.getValue(iter, 2).getInt();


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

class BaseStationTreeView : TreeView {
    BaseStationListStore listStore;
    this() {
	appendColumn(new StationTextColumn("ID", Column.Id));
	appendColumn(new StationTextColumn("Name", Column.Name));
	appendColumn(new StationTypeCol());
	appendColumn(new StationTextColumn("Serial", Column.Serial));
	appendColumn(new StationTextColumn("Signal Strength", Column.Strength));
	appendColumn(new BatteryLevelCol());
	appendColumn(new StationTextColumn("Working Mode", Column.WorkingMode));
	
	auto model = new BaseStationModel("http://localhost:8080/radios");

	auto listStore = new BaseStationListStore(model);
	this.listStore = listStore;
	setModel(listStore);
    }
}
