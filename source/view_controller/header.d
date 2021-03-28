/// Moduel defining apps headerbar
module konsola_operatorska.view_controller.header;

import konsola_operatorska.view_controller.error_triangle;
import konsola_operatorska.model.stations;

import std.string;
import std.random;

import gtk.HeaderBar;
import gtk.Label;
import gtk.Box;

string getRandomSplash()
{
    string[] splashes = import("splashes.txt").split("\n");
    return choice(splashes);
}

class Header : HeaderBar
{
    this(StationModel model)
    {
        super();
        packStart(new ErrorTriangle(model));

        this.setTitleWidget(new Label("Konsola Operatorska"));
        //	setSubtitle(getRandomSplash());
        setShowTitleButtons(true);
    }
}
