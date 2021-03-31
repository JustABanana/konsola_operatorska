/// 
module konsola_operatorska.station;

import std.stdio;
import std.json;
import jsonizer.fromjson;
import jsonizer.jsonize;
import jsonizer;

import std.algorithm.comparison : equal;

enum WorkingMode
{
    Idle = 0,
    Voice,
    Data,
}

enum StationType
{
    Portable = 0,
    Car,
    BaseStation,
}

/** 
  * Converts the station type enum to an icon name 
  * Returns: A gtk icon name
  */
string stationTypeToIconName(StationType type) pure nothrow
{
    final switch (type)
    {
    case StationType.Portable:
        return "mobile-symbolic";
    case StationType.Car:
        return "truck-symbolic";
    case StationType.BaseStation:
        return "broadcast-tower-symbolic";
    }
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
/** A struct representing the station as sent to us by the server, 
    deserialized from json */
struct Station
{
    mixin JsonizeMe;
    @jsonize("Id") int id;
    @jsonize("Name") string name;
    @jsonize("Type") StationType type;
    @jsonize("SerialNumber") string serialNumber;
    @jsonize("Strength") int strength; /// Signal strength(values from 0 to 10)
    @jsonize("BatteryLevel") int batteryLevel; /// Battery level(in percentage, values from 1 to 100)
    @jsonize("WorkingMode") WorkingMode workingMode;
    @jsonize("Position") Position position;

    /**
     * Estimate the station health based on the signal strength, battery level, station type and working mode
     * Returns: A value from 1-100 with an estimate of how well the station is doing(1- worst, 100- best)
     * The function to estimate the value is defined as:
     * 1. Calculate the importance of battery level and signal
     * * importance of signal is:
     * * + 1 for working mode idle
     * * + 2 for working mode data
     * * + 3 for working mode voice
     * * + the importance comes from estimates of how bad it is for the user to lose signal in any of the situtations
     * * importance of battery is:
     * * + 0 for working mode tower
     * * + 1 for working mode car
     * * + 3 for working mode portable
     * * + the importance comes from estimates of how likely it is for the battery to die
     * 2. Calculate the value of the battery level 
     * We use f(x) = sqrt(100x) for calculating the value, because that function gives us a nice curve, where the difference between 100% to 99% is less than the difference between 3% to 1%
     * 3. Calculate the value of the signal strength
     * * We simply scale the signal strength to match the range of the battery level(1-100)
     * 4. We calculate the weighted average using the importance as the weight and the value as the value
     */
    uint calcStationHealth() pure
    {
        // Rounding is ok, since this isn't a precise calculation but a rough estimate
        import std.math : sqrt, round;
        import std.conv;

        uint batteryImportance = 1;
        uint signalImportance = 1;

        final switch (this.workingMode)
        {
        case WorkingMode.Idle:
            // In idle mode signal strength isn't very important
            signalImportance = 1;
            break;
        case WorkingMode.Data:
            // Data transfer interruptions aren't as bad as voice interruptions
            signalImportance = 2;
            break;
        case WorkingMode.Voice:
            // Voice needs the transfer of data to be uniterrupted, otherwise we risk poor UX
            signalImportance = 3;
            break;
        }

        final switch (this.type)
        {
        case StationType.BaseStation:
            /// Battery never runs out in a tower
            batteryImportance = 0;
            break;
        case StationType.Car:
            /// Batteries are much easier to charge in a car
            batteryImportance = 1;
            break;
        case StationType.Portable:
            /// Mobile devices running out of batteries are the biggest issue
            batteryImportance = 3;
            break;
        }
        /* 
	    * Use a square rase oot function so the difference between 100% and 99% of battery
	    * is less impactful than the difference between 2-1%.
	    * The higher the chance of someone not charing the battery in the device the lower the health should be.
	    * The sqrt(100x) function for x > 0 && x < 100 always returns a value in the range of 0 to 100
	*/
        uint batteryValue = round(sqrt((100 * this.batteryLevel).to!float)).to!uint;

        // Scale signal to 1-100
        uint scaledSignal = this.strength * 10;

        // Return a weighted average
        return (scaledSignal * signalImportance + batteryValue * batteryImportance) / (
                signalImportance + batteryImportance);
    }

    @("calcStationHealth returns the correct max and min values")
    unittest
    {
        Station* station = new Station(1, "foo", StationType.Portable, "bar",
                0, 0, WorkingMode.Voice);
        station.strength = 10;
        station.batteryLevel = 100;

        uint health = station.calcStationHealth();
        assert(health == 100);

        station.strength = 0;
        station.batteryLevel = 0;
        health = station.calcStationHealth();
        assert(health == 0);
    }
}

/// Example usage with the jsonize.fromJSONString function
@("Station correctly deserializes from json")
unittest
{
    import std.math : isClose;

    string jsonStr = `{"Id":1,"Name":"KR 1","Type":"Portable","SerialNumber":"4686-4706-1775-00001","Strength":1,"BatteryLevel":25,"WorkingMode":"Voice","Position":{"Lat":"50.06528","Lon":"19.95947"}}`;

    auto bs = fromJSONString!Station(jsonStr);
    assert(bs.id == 1);
    assert(bs.name == "KR 1");
    assert(bs.type == StationType.Portable);
    assert(bs.serialNumber == "4686-4706-1775-00001");
    assert(bs.strength == 1);
    assert(bs.batteryLevel == 25);
    assert(bs.workingMode == WorkingMode.Voice);
    assert(isClose(bs.position.lat, 50.06528));
    assert(isClose(bs.position.lon, 19.95947));
}
