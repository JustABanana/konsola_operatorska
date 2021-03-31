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
import gtk.TreeSelection;
import gtk.TreeIter;

import std.stdio;
import std.meta;
import std.typecons;
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

extern (C)
{
    /// Function passed to gtk in a TreeViewColumn to convert the StationType enum into a CellRendererPixbuf 
    void stationTypeCellDataFunc(GtkTreeViewColumn* col_c, GtkCellRenderer* ren_c,
            GtkTreeModel* model_c, GtkTreeIter* iter_c, void* data)
    {
        // Convert arguments from C types to D types
        auto ren = new CellRenderer(ren_c);
        auto model = new ListStore(cast(GtkListStore*) model_c);
        auto iter = new TreeIter(iter_c);

        Value val;
        model.getValue(iter, Column.Type, val);

        StationType stationType = cast(StationType) val.getInt();

        ren.setProperty("icon-name", stationTypeToIconName(stationType));
    }
}

class StationTypeCol : TreeViewColumn
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

class BatteryLevelCol : TreeViewColumn
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

class SignalStrengthCol : TreeViewColumn
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

class StationTreeView : TreeView
{
    StationListStore listStore;
    StationModel stationModel;
    this(StationModel model)
    {
        this.stationModel = model;
        appendColumn(new StationTextColumn("ID", Column.Id));
        appendColumn(new StationTextColumn("Name", Column.Name));
        appendColumn(new StationTypeCol());
        appendColumn(new StationTextColumn("Serial", Column.Serial));
        appendColumn(new SignalStrengthCol());
        appendColumn(new BatteryLevelCol());
        appendColumn(new StationTextColumn("Working Mode", Column.WorkingMode));

        auto listStore = new StationListStore(model);
        this.listStore = listStore;

        this.getSelection().addOnChanged((TreeSelection sel) {
            TreeIter iter;
            TreeModelIF model;

            if (sel.getSelected(model, iter))
            {
                Value val;
                model.getValue(iter, Column.Id, val);
                int id = val.getInt();

                Station* station = id in this.stationModel.stations;
                // We want to crash if station is null, since that means our local model is broken
                assert(station);

                this.stationModel.SelectionChanged.emit((*station).nullable);
            }
            else
            {
                this.stationModel.SelectionChanged.emit(Nullable!Station.init);
            }
        });

        setModel(listStore);
    }
}

/// Pseudo model for using the station model with GTK's tree view
class StationListStore : ListStore
{
    StationModel model;
    TreeIter[int] idToIter;

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

	model.StationAdded.connect(&this.onStationAdded);
	model.StationChanged.connect(&this.onStationChanged);
	model.StationRemoved.connect(&this.onStationRemoved);

	foreach(station; model.stations.values()) {
	    this.onStationAdded(station);
	}
    }

    void onStationAdded(Station station) {
	auto iter = this.createIter();
	this.idToIter[station.id] = iter;
	setStationRow(iter,station);
    }

    void onStationChanged(Station station) {
            if (auto iter = station.id in this.idToIter)
	    {
		this.setStationRow(*iter, station);
	    }
    }

    void onStationRemoved(Station station) {
            if (auto iter = station.id in this.idToIter)
	    {
		this.remove(*iter);
		this.idToIter.remove(station.id);
	    }
    }

    void setStationRow(TreeIter iter, Station station) {
		setValue(iter, Column.Id, station.id);
		setValue(iter, Column.Name, station.name);
		setValue(iter, Column.Type, station.type);
		setValue(iter, Column.Serial, station.serialNumber);
		setValue(iter, Column.Strength, station.strength*10); // Times 10, to get strength as a percentage
		setValue(iter, Column.BatteryLevel, station.batteryLevel);
		setValue(iter, Column.WorkingMode, station.workingMode.to!string);

    }

}
