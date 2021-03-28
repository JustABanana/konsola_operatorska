///
module konsola_operatorska.app;

import gtk.Window;
import gtk.ApplicationWindow;
import gtk.Application;
import gtk.Box;
import gtk.IconTheme;
import gobject.Signals;

import konsola_operatorska.assets;
import konsola_operatorska.header;
import konsola_operatorska.basestation;
import konsola_operatorska.basestation_model;
import konsola_operatorska.basestation_treeview;
import konsola_operatorska.error_triangle;

class AdminConWindow : ApplicationWindow
{
    this(Application app)
    {
        super(app);

        loadResources();
        addIcons();
        addStyles();

        Box box = new Box(GtkOrientation.HORIZONTAL, 10);

        auto model = new BaseStationModel("http://localhost:8080/radios");

        auto bs_tv = new StationTreeView(model);

        box.append(bs_tv);
        this.setChild(box);

        auto header = new Header(model);
        setTitlebar(header);

        setDefaultSize(0, 600);
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
