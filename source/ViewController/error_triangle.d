module konsola_operatorska.error_triangle;

import konsola_operatorska.basestation_model;

import gtk.Image;
import gtk.IconTheme;
import gtk.StyleContext;
import gdk.Display;

class ErrorTriangle : Image
{
    BaseStationModel model;
    this(BaseStationModel model)
    {
        auto icon = IconTheme.getForDisplay(Display.getDefault()).lookupIcon("exclamation-triangle-symbolic",
                [], 128, 1, GtkTextDirection.LTR, GtkIconLookupFlags.PRELOAD);
        super(icon);

        this.model = model;
        model.FetchingSucessful.connect(&this.onFetchSuccessful);
        model.FetchingFailed.connect(&this.onFetchFailed);

        StyleContext sc = this.getStyleContext();
        sc.addClass("error-triangle");

    }

    void onFetchSuccessful()
    {
        this.hide();
    }

    void onFetchFailed(FetchingError e)
    {
        this.show();

        this.setTooltipText(e.msg);
        this.setHasTooltip(true);
    }
}
