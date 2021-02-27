import std.stdio;
import std.json;
import jsonizer.fromjson;
import jsonizer.jsonize;
import jsonizer;

import soup.Session;
import soup.Message;
import soup.MessageBody;
import utils : delegateToCallbackTuple;

enum WorkingMode
{
    Idle,
    Voice,
    Data,
}

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

void fetchBaseStations(void delegate(BaseStation[]) okCallback)
{
    Session sess = new Session();
    Message msg = new Message("GET", "http://localhost:8080/radios");
    msg.addOnGotBody((Message m) { 
            string jsonStr = m.responseBody.data();
            BaseStation[] stations = fromJSONString!(BaseStation[])(jsonStr);
            okCallback(stations);
    });

    sess.queueMessage(msg, null, null);
}
@("Fetch basestation correctly from the server")
unittest
{
    import glib.MainLoop;
    import std.socket;
    import std.stdio;
    import std.algorithm: any;


    // Check if there is a server running on port 8080
    auto addresses = getAddress("localhost",8080);
    bool connected = addresses.any!((a) { 
            try {
                new TcpSocket(a);
            } catch (SocketException e) {
               return false; 
            }
            return true;
    });
    if(!connected)  {
        stderr.writefln("Couldn't connect to localhost:8080, is your server running");
        assert(false);
    }

    bool ok = false;
    bool* ok_ptr = &ok;

    auto loop = new MainLoop(null);
    fetchBaseStations((BaseStation[] bs) {
               *ok_ptr = true; 
               loop.quit();
            });
    loop.run();

    assert(ok);
}

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
