/// 
module konsola_operatorska.basestation;

import std.stdio;
import std.format;
import std.json;
import jsonizer.fromjson;
import jsonizer.jsonize;
import jsonizer;

import soup.Session;
import soup.Message;
import soup.MessageBody;

enum WorkingMode
{
    Idle,
    Voice,
    Data,
}

/** Simple position struct containing the lattitude and the longitude. 
    Can be serialized and deserialized with jsonizer. */
struct Position
{
    mixin JsonizeMe;
    @jsonize("Lat") float lat;
    @jsonize("Lon") float lon;
}

/*
Example station serialized as json
{"Id":1,"Name":"KR 1","Type":"Portable","SerialNumber":"4686-4706-1775-00001","Strength":1,"BatteryLevel":25,"WorkingMode":"Idle","Position":{"Lat":"50.06528","Lon":"19.95947"}}
*/
/** A struct representing the base station as sent to us by the server, 
    deserialized from json */
struct BaseStation
{
    mixin JsonizeMe;
    @jsonize("Id") int id;
    @jsonize("Name") string name;
    @jsonize("Type") string type;
    @jsonize("SerialNumber") string serialNumber;
    @jsonize("Strength") int strength;
    @jsonize("BatteryLevel") int batteryLevel;
    @jsonize("WorkingMode") WorkingMode workingMode;
    @jsonize("Position") Position position;

}

/// Example usage with the jsonize.fromJSONString function
@("BaseStation correctly deserializes from json")
unittest
{
    import std.math : approxEqual;

    string jsonStr = `{"Id":1,"Name":"KR 1","Type":"Portable","SerialNumber":"4686-4706-1775-00001","Strength":1,"BatteryLevel":25,"WorkingMode":"Voice","Position":{"Lat":"50.06528","Lon":"19.95947"}}`;

    BaseStation bs = fromJSONString!BaseStation(jsonStr);
    assert(bs.id == 1);
    assert(bs.name == "KR 1");
    assert(bs.type == "Portable");
    assert(bs.serialNumber == "4686-4706-1775-00001");
    assert(bs.strength == 1);
    assert(bs.batteryLevel == 25);
    assert(bs.workingMode == WorkingMode.Voice);
    assert(approxEqual(bs.position.lat, 50.06528));
    assert(approxEqual(bs.position.lon, 19.95947));
}

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

void fetchBaseStations(void delegate(BaseStation[]) okCallback,
        void delegate(BaseStationFetchingError) errCallback)
{
    Session sess = new Session();
    Message msg = new Message("GET", "http://localhost:8080/radios");
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

@("Fetch basestation correctly from the server")
unittest
{
    import glib.MainLoop;
    import glib.MainContext;
    import std.socket;
    import std.stdio;
    import std.algorithm : any;

    // Check if there is a server running on port 8080
    auto addresses = getAddress("localhost", 8080);
    bool connected = addresses.any!((a) {
        try
        {
            new TcpSocket(a);
        }
        catch (SocketException e)
        {
            return false;
        }
        return true;
    });
    if (!connected)
    {
        throw new Exception("[test runner] Couldn't connect to localhost:8080, is your server running");
    }

    bool ok = false;
    bool* ok_ptr = &ok;

    auto loop = new MainLoop(new MainContext(null), true);

    fetchBaseStations((BaseStation[] bs) { *ok_ptr = true; loop.quit(); },
         (BaseStationFetchingError e) {
      if (cast(ServerError)e)
        {
            *ok_ptr = true;
        }
        else
        {
            *ok_ptr = false;
        }
        loop.quit();
    });

    loop.run();
    assert(ok);
}

