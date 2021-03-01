import std.stdio;
import std.random;
import std.string;
import gtk.MainWindow;
import gtk.Window;
import gtk.Label;
import gtk.Widget;
import gtk.Container;
import gtk.Main;
import std.functional : toDelegate;
import jsonizer.tojson;
import basestation;

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
        //fetchBaseStations((BaseStation[] bs) => writeln("aaaa"));
        Main.run();
    }
}
