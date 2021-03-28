/// Moduel defining apps headerbar
module konsola_operatorska.header;

import konsola_operatorska.error_triangle;
import konsola_operatorska.basestation_model;
import konsola_operatorska.error_triangle;

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
    this(BaseStationModel model)
    {
        super();
        packStart(new ErrorTriangle(model));

        this.setTitleWidget(new Label("Konsola Operatorska"));
        //	setSubtitle(getRandomSplash());
        setShowTitleButtons(true);
    }
}
