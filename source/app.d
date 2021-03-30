///
module konsola_operatorska.app;

import gtk.Window;
import gtk.ApplicationWindow;
import gtk.Application;
import gtk.Box;
import gtk.IconTheme;
import gobject.Signals;

import konsola_operatorska.assets;
import konsola_operatorska.station;

import konsola_operatorska.model.stations;

import konsola_operatorska.view_controller.map;
import konsola_operatorska.view_controller.header;
import konsola_operatorska.view_controller.treeview;

class AdminConWindow : ApplicationWindow
{
    this(Application app)
    {
        super(app);

        loadResources();
        addIcons();
        addStyles();

        auto box = new Box(GtkOrientation.VERTICAL, 3);

        auto model = new StationModel("http://localhost:8080/radios");

        auto s_tv = new StationTreeView(model);
        auto map = new Mapview(model);

        box.append(s_tv);
        map.setValign(GtkAlign.FILL);

        box.append(map);
        this.setChild(box);

        auto header = new Header(model);
        setTitlebar(header);
        this.setDefaultSize(800, 600);

        this.maximize();

        this.show();
        box.show();
    }
}

version (unittest)
{
    // Make sure we don't have a main in unittests
}
else
{
    void main(string[] args)
    {
        Application app = new Application(null, GApplicationFlags.FLAGS_NONE);
        Signals.connect(app, "activate", () => new AdminConWindow(app));
        app.run(args);
    }
}
