/// A small utility function to make sure that there is a server at address that has the specified port open 
bool isServerRunning(string address, ushort port)
{
    import std.socket;
    import std.algorithm : any;

    // Check if there is a server running on port 8080
    auto addresses = getAddress(address, port);
    return addresses.any!((a) {
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
}
