module konsola_operatorska.basestation_model;
import konsola_operatorska.basestation;

import std.signals;
import std.stdio;
import std.format;

import soup.Session;
import soup.Message;
import soup.MessageBody;

import jsonizer.fromjson;
import jsonizer.jsonize;
import jsonizer;

import glib.Timeout;

/// Abstract class for exceptions that can occur when fetching base stations from the server.
abstract class BaseStationFetchingError : Exception
{
    Status statusCode;
    this(string msg = "", Status statusCode = Status.NONE,
            string file = __FILE__, size_t line = __LINE__)
    {
        this.statusCode = statusCode;
        super(msg, file, line);
    }
}

/// Instantiated where there was a problem connecting to the server
class ConnectionError : BaseStationFetchingError
{
    this(Status statusCode = SoupStatus.NONE, string file = __FILE__, size_t line = __LINE__)
    {
        super(format("Couldn't connect to the server: %s", statusCode), statusCode, file, line);
    }
}

/// Instantiated where an error occured on the server(status codes 500-599)
class ServerError : BaseStationFetchingError
{
    this(SoupStatus statusCode = SoupStatus.NONE, string file = __FILE__, size_t line = __LINE__)
    {
        super(format("A server error occured: %s", statusCode), statusCode, file, line);
    }
}

/**
   Instantiated when the server returns a status code that indicates a 
   client error(status codes 400-499 or 3xx status codes that aren't 
   just redirections) 
*/
class ClientError : BaseStationFetchingError
{
    this(SoupStatus statusCode = SoupStatus.NONE, string file = __FILE__, size_t line = __LINE__)
    {
        super(format("A client error occured, server sent: %s", statusCode), statusCode, file, line);
    }
}

/// Class used to fetch basestations from the server. 
class BaseStationFetcher
{
    string url;
    Session sess;

    /***********************************
     * Params:
     *         url = a string representing the url on the server to fetch the radios from, for example "http://localhost:8080/radios"
     */
    this(string url)
    {
        this.url = url;
        this.sess = new Session();
    }

    void fetchBaseStations(void delegate(BaseStation[]) okCallback,
            void delegate(BaseStationFetchingError) errCallback)
    {
        Message msg = new Message("GET", url);

        msg.addOnFinished((Message m) {

            SoupStatus statusCode = cast(SoupStatus)(m.getMessageStruct().statusCode);

            // Check if an error occured
            if (statusCode >= 200 && statusCode < 300) // Everything is ok!
            {
                string jsonStr = m.responseBody.data();
                BaseStation[] stations = fromJSONString!(BaseStation[])(jsonStr);
                okCallback(stations);
            }
            else if (statusCode > 0 && statusCode < 100) /* Status codes in the range of 1-100 are used 
               by libsoup to indicate connection errors */
            {
                errCallback(new ConnectionError(statusCode));
            }
            else if (statusCode >= 300 && statusCode < 500) /* Status codes from 300-500 indicate that our client messed up
               Since libsoup handles redirects for us we can assume every 
               other status code is our mistake */
            {
                errCallback(new ClientError(statusCode));
            }
            else if (statusCode >= 500) /* Status codes higher or equal than 500
               indicate server errors */
            {
                errCallback(new ConnectionError(statusCode));
            }

        });

        sess.queueMessage(msg, null, null);
    }
}

///
@("Fetch basestations from the server")
unittest
{
    import glib.MainLoop;
    import glib.MainContext;
    import test_utils : isServerRunning;

    if (!isServerRunning("localhost", 8080))
    {
        throw new Exception("[test] Couldn't connect to localhost:8080, is your server running");
    }

    auto loop = new MainLoop(new MainContext(null), true);
    auto fetcher = new BaseStationFetcher("http://localhost:8080/radios");
    BaseStationFetchingError err = null;

    fetcher.fetchBaseStations((BaseStation[] bs) => loop.quit(), (BaseStationFetchingError e) {
        if (!cast(ServerError) e)
        {
            err = e;
        }
        loop.quit();
    });

    loop.run();
    if (err)
        throw err;
}

class StationWithEvents {
    BaseStation station;
    mixin Signal!() Changed;
    mixin Signal!() Removed;
    this(BaseStation station) {
        this.station = station;
    }
}

class BaseStationModel
{
    /// Map of basestation id to basestations
    StationWithEvents[int] stations;
    BaseStationFetcher fetcher;

    /***********************************
         * Params:
         *         url = the url to pass to the BaseStationFetcher
         */
    this(string url)
    {
        this.fetcher = new BaseStationFetcher(url);

        // Start fetching and updating the model
        new Timeout(5000, {
            this.fetcher.fetchBaseStations((BaseStation[] bs) => this.updateItems(bs),
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
