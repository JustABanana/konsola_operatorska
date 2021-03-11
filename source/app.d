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
import konsola_operatorska.basestation_treeview;

string getRandomSplash()
{
    string[] splashes = import("splashes.txt").split("\n");
    return choice(splashes);
}

class MyApplication : Application
{
    import gtkd.Implement;
    import gobject.c.functions : g_object_newv;

    mixin ImplementClass!GtkApplication;

    this()
    {

        super(null, GApplicationFlags.FLAGS_NONE);
    }
}

class AdminConWindow : MainWindow
{
    this()
    {
        super("Konsola Operatorska: " ~ getRandomSplash());
        auto bs_tv = new BaseStationTreeView();

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
