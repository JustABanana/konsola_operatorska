/// Loads assets from the gresource.xml file in the $PROJECT_ROOT/assets directory
module konsola_operatorska.assets;

import gio.Resource;
import gtk.IconTheme;
import glib.Bytes;

import std.stdio;
import std.array;

void loadResource()
{
    ubyte[] assets = cast(ubyte[]) import("assets/generated/res.gresource");
    Bytes bytes = new Bytes(assets);
    Resource res = new Resource(bytes);
    Resource.register(res);
}

void addIcons()
{
    IconTheme.getDefault().addResourcePath("/icons");
    IconTheme.getDefault().addResourcePath("/");
}
