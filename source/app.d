///
module konsola_operatorska.app;

import gtk.MainWindow;
import gtk.Main;
import gtk.ListStore;
import gtk.TreeIter;
import gtk.Application;
import gtk.Box;

import konsola_operatorska.assets;
import konsola_operatorska.header;
import konsola_operatorska.basestation;
import konsola_operatorska.basestation_model;
import konsola_operatorska.basestation_treeview;

import konsola_operatorska.error_triangle;



class AdminConWindow : MainWindow
{
    this()
    {
        super("Konsola Operatorska");

        loadResources();
        addIcons();
        addStyles();

        Box box = new Box(GtkOrientation.HORIZONTAL, 10);

        auto model = new BaseStationModel("http://localhost:8080/radios");
        auto bs_tv = new StationTreeView(model);

        box.add(bs_tv);
        add(box);

        auto header = new Header(model);
        setTitlebar(header);

        setDefaultSize(0, 600);
        showAll();

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
        Main.init(args);
        AdminConWindow win = new AdminConWindow();
        Main.run();
    }
}
