FROM ubuntu:jammy
WORKDIR /opt/tvb-build 
COPY src ./src
COPY macos-xcode ./macos-xcode
COPY godot-cpp ./godot-cpp
COPY SConstruct ./SConstruct
COPY docker/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    git\
    ca-certificates \
    python3-pip \
    bash \
    gcc-mingw-w64-x86-64-posix \
    g++-mingw-w64-x86-64-posix \
    clang \
    cmake \
    patch \
    python-is-python3 \
    libssl-dev \
    liblzma-dev \
    lzma-dev \
    libxml2-dev \
    xz-utils \
    bzip2 \
    cpio \
    libbz2-dev \
    zlib1g-dev
## Install emscripten SDK
RUN git clone https://github.com/emscripten-core/emsdk.git && cd emsdk && ./emsdk install latest && ./emsdk activate latest && . ./emsdk_env.sh

## Install osxcross
RUN cd /opt/tvb-build && git clone https://github.com/tpoechtrager/osxcross.git ./osxcross && cd osxcross && ./tools/gen_sdk_package_tools_dmg.sh /opt/tvb-build/macos-xcode/Command_Line_Tools_for_Xcode_16.4.dmg && mv MacOSX*.sdk.tar.xz ./tarballs && SDK_VERSION=14 UNATTENDED=1 ./build.sh

RUN pip install scons

ENTRYPOINT ["/bin/bash","/opt/tvb-build/entrypoint.sh"]
