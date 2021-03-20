/// 
module konsola_operatorska.basestation;

import std.stdio;
import std.json;
import jsonizer.fromjson;
import jsonizer.jsonize;
import jsonizer;

import std.algorithm.comparison : equal;


enum WorkingMode
{
    Idle,
    Voice,
    Data,
}

enum DeviceType
{
    Portable,
    Car,
    BaseStation,
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
    @jsonize("Type") DeviceType type;
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
    assert(bs.type == DeviceType.Portable);
    assert(bs.serialNumber == "4686-4706-1775-00001");
    assert(bs.strength == 1);
    assert(bs.batteryLevel == 25);
    assert(bs.workingMode == WorkingMode.Voice);
    assert(approxEqual(bs.position.lat, 50.06528));
    assert(approxEqual(bs.position.lon, 19.95947));
}
