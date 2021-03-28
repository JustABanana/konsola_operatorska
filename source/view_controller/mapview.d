module konsola_operatorska.view_controller.map;
import konsola_operatorska.basestation_model;
class ErrorTriangle : Image
{
    BaseStationModel model;
    this(BaseStationModel model)
    {

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
