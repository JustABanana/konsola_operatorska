/// Module responsible for fetching the data from the server
module konsola_operatorska.station_fetcher;

import konsola_operatorska.basestation;

import std.format;

import soup.Session;
import soup.Message;
import soup.MessageBody;

import jsonizer.fromjson;
import jsonizer.jsonize;
import jsonizer;

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

/// Class used to fetch data from the server. 
class StationFetcher
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

    void fetchStations(void delegate(BaseStation[]) okCallback,
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
@("Fetch stations from the server")
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
    auto fetcher = new StationFetcher("http://localhost:8080/radios");
    BaseStationFetchingError err = null;

    fetcher.fetchStations((BaseStation[] bs) => loop.quit(), (BaseStationFetchingError e) {
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
