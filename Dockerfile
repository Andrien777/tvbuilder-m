FROM ubuntu:jammy
ARG BUILD_WEB=n
ARG BUILD_MACOS=n
ENV BUILD_MACOS=$BUILD_MACOS
ENV BUILD_WEB=$BUILD_WEB


WORKDIR /opt/tvb-build
COPY ./docker/ /opt/tvb-build/docker/
COPY ./macos-xcode/ /opt/tvb-build/macos-xcode/

WORKDIR /opt/tools
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
RUN if [ "$BUILD_WEB" = "y" ] ;then git clone https://github.com/emscripten-core/emsdk.git && cd emsdk && ./emsdk install latest && ./emsdk activate latest && . ./emsdk_env.sh; fi

## Install osxcross
RUN if [ "$BUILD_MACOS" = "y" ] ;then cd /opt/tools && git clone https://github.com/tpoechtrager/osxcross.git ./osxcross && cd osxcross && ./tools/gen_sdk_package_tools_dmg.sh /opt/tvb-build/macos-xcode/Command_Line_Tools_for_Xcode_16.4.dmg && mv MacOSX*.sdk.tar.xz ./tarballs && SDK_VERSION=14 UNATTENDED=1 ./build.sh ; fi
RUN pip install scons

WORKDIR /opt/tvb-build 
RUN chmod +x docker/entrypoint.sh
ENTRYPOINT ["/bin/bash","/opt/tvb-build/docker/entrypoint.sh"]
