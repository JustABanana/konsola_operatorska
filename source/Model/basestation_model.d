module konsola_operatorska.basestation_model;

import konsola_operatorska.basestation;
import konsola_operatorska.station_fetcher;

import std.signals;
import std.stdio;
import std.format;

import glib.Timeout;

class StationWithEvents
{
    BaseStation station;
    mixin Signal!() Changed;
    mixin Signal!() Removed;
    this(BaseStation station)
    {
        this.station = station;
    }
}

class BaseStationModel
{
    /// Map of basestation id to basestations
    StationWithEvents[int] stations;
    StationFetcher fetcher;

    /***********************************
         * Params:
         *         url = the url to pass to the StationFetcher
         */
    this(string url)
    {
        this.fetcher = new StationFetcher(url);

        // Start fetching and updating the model
        new Timeout(5000, {
            this.fetcher.fetchStations((BaseStation[] bs) => this.updateItems(bs),
                (BaseStationFetchingError e) => writeln(e));
            return true;
        }, true);
    }

    void updateItems(BaseStation[] stations)
    {
        StationWithEvents[int] oldStations = this.stations;
        StationWithEvents[int] newStations;

        foreach (newStation; stations)
        {

            if (auto oldStation = newStation.id in oldStations)
            {
                newStations[newStation.id] = *oldStation;
                if (newStation != oldStation.station)
                {
                    oldStation.Changed.emit();
                }

                /* Removing all items that were moved to the new map
		   so we know that the remaining ones were removed */
                oldStations.remove(oldStation.station.id);
            }
            else
            {
                auto newStationEvents = new StationWithEvents(newStation);
                newStations[newStation.id] = newStationEvents;
                StationAdded.emit(newStationEvents);
            }
        }

        // Remove remaining iters
        foreach (removedStation; oldStations.values())
        {
            removedStation.Removed.emit();
        }

        this.stations = newStations;
    }

    mixin Signal!(StationWithEvents) StationAdded;

}
