FROM ubuntu:14.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    gcc \
    libc6-dev \
    make \
    pkg-config

COPY xargo.sh /
RUN bash /xargo.sh

COPY openssl.sh qemu.sh /
RUN apt-get install -y --no-install-recommends \
    g++-arm-linux-gnueabi \
    libc6-dev-armel-cross && \
    bash /openssl.sh linux-armv4 arm-linux-gnueabi- && \
    bash /qemu.sh arm

ENV CARGO_TARGET_ARMV5TE_UNKNOWN_LINUX_GNUEABI_LINKER=arm-linux-gnueabi-gcc \
    CARGO_TARGET_ARMV5TE_UNKNOWN_LINUX_GNUEABI_RUNNER=qemu-arm \
    CC_armv5te_unknown_linux_gnueabi=arm-linux-gnueabi-gcc \
    CFLAGS_armv5te_unknown_linux_gnueabi="-march=armv5te -mfloat-abi=soft" \
    CXX_armv5te_unknown_linux_gnueabi=arm-linux-gnueabi-gcc \
    CXXFLAGS_armv5te_unknown_linux_gnueabi="-march=armv5te -mfloat-abi=soft" \
    OPENSSL_DIR=/openssl \
    OPENSSL_INCLUDE_DIR=/openssl/include \
    OPENSSL_LIB_DIR=/openssl/lib \
    QEMU_LD_PREFIX=/usr/arm-linux-gnueabi \
    RUST_TEST_THREADS=1
