/// Moduel defining apps headerbar
module konsola_operatorska.view_controller.header;

import konsola_operatorska.view_controller.error_triangle;
import konsola_operatorska.model.stations;

import std.string;
import std.random;

import gtk.HeaderBar;
import gtk.Label;
import gtk.CenterBox;

string getRandomSplash()
{
    string[] splashes = import("splashes.txt").split("\n");
    return choice(splashes);
}

class TitleWithSubtitle : CenterBox 
{
    this() 
    {
        super();
        this.setOrientation(GtkOrientation.VERTICAL);
        auto titleLabel = new Label("Konsola Operatorska");
        titleLabel.getStyleContext().addClass("title");

        auto subTitleLabel = new Label(getRandomSplash());
        subTitleLabel.getStyleContext().addClass("subtitle");

        this.setCenterWidget(titleLabel);
        this.setEndWidget(subTitleLabel);
    }

}

class Header : HeaderBar
{
    this(StationModel model)
    {
        super();
        packStart(new ErrorTriangle(model));

        this.setTitleWidget(new TitleWithSubtitle());
        setShowTitleButtons(true);
    }
}
