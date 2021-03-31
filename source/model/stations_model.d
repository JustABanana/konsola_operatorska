module konsola_operatorska.model.stations;

import konsola_operatorska.station;
import konsola_operatorska.station_fetcher;

public import konsola_operatorska.station_fetcher : FetchingError,
    ConnectionError, ServerError, ClientError;

import std.signals;
import std.stdio;
import std.format;
import std.typecons;

import glib.Timeout;

class StationModel
{
    /// Map of station id to station 
    Station[int] stations;
    StationFetcher fetcher;
    Nullable!Station currentSelection;

    /***********************************
         * Params:
         *         url = the url to pass to the StationFetcher
         */
    this(string url)
    {
        this.fetcher = new StationFetcher(url);

        // Start fetching and updating the model
        new Timeout(5000, {
            this.fetcher.fetchStations((Station[] bs) {
                this.updateItems(bs);
                this.FetchingSucessful.emit();
            }, (FetchingError e) { this.FetchingFailed.emit(e); });
            return true;
        }, true);
    }

    void changeSelection(Nullable!Station station) {
        this.SelectionChanged.emit(station);
    }

    void updateItems(Station[] newStations)
    {
        Station[int] oldStations = this.stations;
        Station[int] newStationsMember;

        foreach (newStation; newStations)
        {
            if (auto oldStation = newStation.id in oldStations)
            {
                newStationsMember[newStation.id] = *oldStation;
                if (newStation != *oldStation)
                {
                    this.StationChanged.emit(newStation);
                }

                /* Removing all items that were moved to the new map
		   so we know that the remaining ones were removed */
                oldStations.remove(oldStation.id);
            }
            else
            {
                newStationsMember[newStation.id] = newStation;
                this.StationAdded.emit(newStation);
            }
        }

        // Remove remaining iters
        foreach (removedStation; oldStations.values())
        {
            this.StationRemoved.emit(removedStation);
        }

        this.stations = newStationsMember;
    }

    mixin Signal!(Station) StationAdded;
    mixin Signal!(Station) StationChanged;
    mixin Signal!(Station) StationRemoved;

    mixin Signal!(Nullable!Station) SelectionChanged;

    mixin Signal!() FetchingSucessful;
    mixin Signal!(FetchingError) FetchingFailed;

}
