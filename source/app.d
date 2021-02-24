import std.stdio;
import std.random;
import std.string;
import gtk.MainWindow;
import gtk.Main;

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

void main(string[] args)
{
    Main.init(args);
    new AdminConWindow();
    Main.run();
}
