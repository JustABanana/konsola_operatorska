module konsola_operatorska.error_triangle;

import konsola_operatorska.basestation_model;

import gtk.Image;
import gtk.StyleContext;

class ErrorTriangle : Image {
	BaseStationModel model;
	this(BaseStationModel model) {
		super("exclamation-triangle-symbolic", IconSize.LARGE_TOOLBAR);
		this.model = model;
		model.FetchingSucessful.connect(&this.onFetchSuccessful);
		model.FetchingFailed.connect(&this.onFetchFailed);

		StyleContext sc = this.getStyleContext();
		sc.addClass("error-triangle");


	}
	void onFetchSuccessful() {
		this.hide();
	}
	void onFetchFailed(FetchingError e) {
		this.show();

		this.setTooltipText(e.msg);
		this.setHasTooltip(true);
	}
}
