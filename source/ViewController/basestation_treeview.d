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
import gtk.ListStore;
import gtk.TreeIter;

import std.stdio;
import std.meta;

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
		setValue(iter, 0, bs.id);
		setValue(iter, 1, bs.name);
		setValue(iter, 2, bs.type);
		setValue(iter, 3, bs.serialNumber);
		setValue(iter, 4, bs.strength);
		setValue(iter, 5, bs.batteryLevel);
		setValue(iter, 6, bs.workingMode);

    }

}

class StationTextColumn : TreeViewColumn
{
	CellRendererText cellRendererText;
	string attributeType = "text";

	this(string columnTitle, int columnNumber)
	{
		cellRendererText = new CellRendererText();
		
		super(columnTitle, cellRendererText, attributeType, columnNumber);
		setSortColumnId(columnNumber);
		this.setReorderable(true);
		this.setResizable(true);
	} 
} 

class StationTypeCol: TreeViewColumn
{
    CellRendererPixbuf cellRenderer;
    uint columnNumber = 2;
    string columnName = "Type";
    this()
    {
	cellRenderer = new CellRendererPixbuf();
	super(columnName, cellRenderer, "icon-name", columnNumber); 
	cellRenderer.setProperty("icon-name", "broadcast-tower");
	this.setReorderable(true);
	this.setResizable(true);
	this.setSortColumnId(columnNumber);


	this.setCellDataFunc(cellRenderer, delegateToCallbackTuple((GtkTreeViewColumn* col_c, GtkCellRenderer* ren_c, GtkTreeModel* model_c, GtkTreeIter* iter_c) { 
		    // Convert arguments from C types to D types
		    auto ren = new CellRenderer(ren_c);
		    auto model = new TreeModel(model_c);
		    auto iter = new TreeIter(iter_c);

		    StationType bs_type = cast(StationType)model.getValue(iter, 2).getInt();


	        	string typeIconName;
	        	final switch(bs_type) {
	        	    case StationType.Portable:
				typeIconName = "mobile";
				break;
	        	    case StationType.Car:
	        		typeIconName = "truck";
	        		break;
	        	    case StationType.BaseStation:
	        		typeIconName = "broadcast-tower";
				break;
	        	}
		    ren.setProperty("icon-name", typeIconName);
	}).expand, null);
    }
}

class BatteryLevelCol: TreeViewColumn
{
    CellRendererPixbuf cellRenderer;
    this(string columnTitle, int columnNumber)
    {
	cellRenderer = new CellRendererPixbuf();
	cellRenderer.setProperty("icon-name", "broadcast-tower");
	super(columnTitle, cellRenderer, null, columnNumber); 
	this.setReorderable(true);
	this.setResizable(true);
    }
}

class BaseStationTreeView : TreeView {
    BaseStationListStore listStore;
    this() {
	this.addCol("ID", 0);
	this.addCol("Name", 1);
	appendColumn(new StationTypeCol());
	this.addCol("Serial", 3);
	this.addCol("Signal Strength", 4);
	this.addCol("Battery Level", 5);
	this.addCol("Working Mode", 6);
	
	auto model = new BaseStationModel("http://localhost:8080/radios");

	auto listStore = new BaseStationListStore(model);
	this.listStore = listStore;
	setModel(listStore);
    }
    void addCol(string name, int id) {
	appendColumn(new StationTextColumn(name, id));
    }
}
