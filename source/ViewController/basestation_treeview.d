module konsola_operatorska.basestation_treeview;

import konsola_operatorska.basestation;
import konsola_operatorska.basestation_model;

import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.CellRendererText;
import gtk.ListStore;
import gtk.TreeIter;

import std.stdio;

/// Pseudo model for using the basestation_model with GTK's tree view
class BaseStationListStore : ListStore
{
    TreeIter[int] idToIter;
    BaseStationModel model;

    this(BaseStationModel model)
    {
        // Mapping of basestation fields to GTypes
        // dfmt off
        super([
                GType.INT, //Id
		GType.STRING, //Name
		GType.STRING, //Type
		GType.STRING, //SerialNumber
		GType.INT, //Strength
                GType.INT, //BatteryLevel
		GType.STRING, //WorkingMode
        ]);

	this.model = model;

	foreach(station; model.stations.values()) {
	    TreeIter iter = createIter();
	    this.setBaseStationRow(iter,station);
	    this.idToIter[station.id] = iter;
	}

	model.StationAdded.connect(&this.onStationAdded);
	model.StationChanged.connect(&this.onStationChanged);
	model.StationRemoved.connect(&this.onStationRemoved);
    }

    void onStationAdded(BaseStation station) {
	// A station with this ID already exists print a warning and remove the old one
	if(auto iter = station.id in idToIter) {
	    stderr.writefln("Duplicate station ID: %d, removing", station.id);
	    remove(*iter);
	}

	auto iter = createIter();
	idToIter[station.id] = iter;
	setBaseStationRow(iter,station);
    }

    void onStationChanged(BaseStation station) {
	if(auto iter = station.id in idToIter) {
	    setBaseStationRow(*iter,station);
	} else {
	    stderr.writefln("missing station id: %d in chagned signal", station.id);
	    onStationAdded(station);
	}
    }

    void onStationRemoved(BaseStation station) {
	if(auto iter = station.id in idToIter) {
	    remove(*iter);
	} else {
	    stderr.writefln("missing station id: %d in removed signal", station.id);
	}
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

class BaseStationTreeViewColumn : TreeViewColumn
{
	CellRendererText cellRendererText;
	string attributeType = "text";

	this(string columnTitle, int columnNumber)
	{
		cellRendererText = new CellRendererText();
		
		super(columnTitle, cellRendererText, attributeType, columnNumber);
		setSortColumnId(columnNumber);
	} 
} 

class BaseStationTreeView : TreeView {
    BaseStationListStore listStore;
    this() {
	this.addCol("ID", 0);
	this.addCol("Name", 1);
	this.addCol("Type", 2);
	this.addCol("Serial", 3);
	this.addCol("Signal Strength", 4);
	this.addCol("Battery Level", 5);
	this.addCol("Working Mode", 5);
	
	auto model = new BaseStationModel("http://localhost:8080/radios");

	auto listStore = new BaseStationListStore(model);
	this.listStore = listStore;
	setModel(listStore);
    }
    void addCol(string name, int id) {
	appendColumn(new BaseStationTreeViewColumn(name, id));
    }
}
