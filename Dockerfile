FROM alpine:3.12.12 as bitcoin-core

RUN apk add --update alpine-sdk && apk add --no-cache \
        gcc \
        git \
        gnupg \
        libffi \
        musl-dev \
        libffi-dev \
        autoconf \
        automake \
        openssh-client \
        make \
        db-dev \
        openssl \
        openssl-dev \
        boost \
        boost-dev \
        libtool \
        libevent \
        libevent-dev \
        czmq \
        czmq-dev \
        zeromq-dev \
        protobuf-dev \
        sqlite-dev=3.32.1-r1 \
        sqlite-libs

#For old BDB (legacy) wallets
COPY --from=lncm/berkeleydb:db-4.8.30.NC  /opt/  /opt/

ARG VERSION=24.0.1
ENV VERSION=${VERSION}
WORKDIR /tmp

RUN echo "Building ordisrespector Bitcoin version: ${VERSION}"

# Download checksums
RUN wget "https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS"

# Download checksums
RUN wget "https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS.asc"

# Download source code (intentionally different website than checksums)
RUN wget "https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}.tar.gz"

# Verify the checksum

RUN echo "$(grep bitcoin-${VERSION}.tar.gz SHA256SUMS)" | sha256sum -c

RUN curl -s "https://api.github.com/repositories/355107265/contents/builder-keys" | grep download_url | grep -oE "https://[a-zA-Z0-9./-]+" | while read url; do curl -s "$url" | gpg --import; done

# Verify that at lease some of hashes are signed with the previously imported key, these keys are not well maintained.
RUN gpg --verify SHA256SUMS.asc; exit 0

RUN tar -xvf bitcoin-${VERSION}.tar.gz

ENV BITCOIN_PREFIX="/tmp/bitcoin-${VERSION}"

RUN cd ${BITCOIN_PREFIX} && wget -O ordisrespector.patch "https://raw.githubusercontent.com/twofaktor/minibolt/main/resources/ordisrespector.patch"

RUN cd ${BITCOIN_PREFIX} && \
    ./autogen.sh && \
    ./configure LDFLAGS=-L/opt/db4/lib/ CPPFLAGS=-I/opt/db4/include/ \
      --disable-bench \
      --disable-gui-tests \
      --disable-maintainer-mode \
      --disable-man \
      --disable-tests \
      --with-daemon=yes \
      --with-gui=no \
      --with-qrencode=no \
      --with-utils=yes \
      --with-libs=yes

RUN cd ${BITCOIN_PREFIX} && git apply ordisrespector.patch
RUN cd ${BITCOIN_PREFIX} && make -j$(nproc)
#RUN make install

# List installed libs, and binaries pre-strip

RUN cd ${BITCOIN_PREFIX}/src && ls -lh bitcoin-cli bitcoin-tx bitcoin-util bitcoin-wallet bitcoind  

RUN strip ${BITCOIN_PREFIX}/src/bitcoin-cli
RUN strip ${BITCOIN_PREFIX}/src/bitcoin-tx
RUN strip ${BITCOIN_PREFIX}/src/bitcoin-util
RUN strip ${BITCOIN_PREFIX}/src/bitcoin-wallet
RUN strip ${BITCOIN_PREFIX}/src/bitcoind

# List installed libs, and binaries after stripping
RUN cd ${BITCOIN_PREFIX}/src && ls -lh bitcoin-cli bitcoin-tx bitcoin-util bitcoin-wallet bitcoind

# Build stage for compiled artifacts
FROM getumbrel/bitcoind:v24.0.1 AS final

ARG VERSION=24.0.1
ARG BITCOIN_PREFIX="/tmp/bitcoin-${VERSION}/src"
ARG UMBREL_BIN_PATH="/usr/local/bin"

COPY --chown=root:root --from=bitcoin-core ${BITCOIN_PREFIX}/bitcoind ${UMBREL_BIN_PATH}
COPY --chown=root:root --from=bitcoin-core ${BITCOIN_PREFIX}/bitcoin-cli ${UMBREL_BIN_PATH}
COPY --chown=root:root --from=bitcoin-core ${BITCOIN_PREFIX}/bitcoin-tx ${UMBREL_BIN_PATH}
COPY --chown=root:root --from=bitcoin-core ${BITCOIN_PREFIX}/bitcoin-util ${UMBREL_BIN_PATH}
COPY --chown=root:root --from=bitcoin-core ${BITCOIN_PREFIX}/bitcoin-wallet ${UMBREL_BIN_PATH}
