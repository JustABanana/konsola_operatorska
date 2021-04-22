FROM fedora
RUN ["dnf", "update", "-y"]
RUN ["dnf", "install", "gtk4", "gtk4-devel", "libsoup", "libsoup-devel", "git", "ninja-build", "meson", "ldc","gobject-introspection", "gobject-introspection-devel" , "-y"]

WORKDIR /
RUN ["mkdir", "dub", "dmd"]

RUN ["git", "clone", "https://gitlab.gnome.org/GNOME/libshumate.git"]
WORKDIR /libshumate
RUN ["git", "checkout","957a56611cbaca9aec51d157ce5a437196a71be4"]
RUN ["mkdir", "build"]
WORKDIR /libshumate/build
RUN ["meson", "--prefix", "/usr/", ".."]
RUN ["ninja"]
RUN ["ninja",  "install"]

WORKDIR /dub
RUN ["curl", "-L", "-o", "dub.tar.gz", "https://github.com/dlang/dub/releases/download/v1.23.0/dub-v1.23.0-linux-x86_64.tar.gz"]
RUN ["tar", "-xzf", "dub.tar.gz"]
RUN ["install", "dub", "/usr/local/bin"]

WORKDIR /dmd
RUN ["curl", "-L", "-o", "dmd.rpm", "https://s3.us-west-2.amazonaws.com/downloads.dlang.org/releases/2021/dmd-2.096.0-0.fedora.x86_64.rpm"]
RUN ["dnf", "install", "dmd.rpm", "-y"]

RUN ["useradd", "-m", "user"]
RUN ["chown", "-R", "user", "/dub"]

CMD ["bash", "-i"]
