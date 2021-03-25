///
module konsola_operatorska.app;

import std.stdio;
import std.random;
import std.string;

import gtk.MainWindow;
import gtk.Main;
import gtk.ListStore;
import gtk.TreeIter;
import gtk.Application;

import konsola_operatorska.basestation;
import konsola_operatorska.basestation_model;
import konsola_operatorska.basestation_treeview;
import konsola_operatorska.assets;

string getRandomSplash()
{
    string[] splashes = import("splashes.txt").split("\n");
    return choice(splashes);
}

class AdminConWindow : MainWindow
{
    this()
    {
        super("Konsola Operatorska: " ~ getRandomSplash());

        auto stationModel = new BaseStationModel("http://localhost:8080/radios");

        auto bs_tv = new StationTreeView(stationModel);

        loadResource();
        addIcons();

        add(bs_tv);
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
