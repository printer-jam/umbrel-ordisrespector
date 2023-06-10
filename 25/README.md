# Umbrel Bitcoin Node #ordisrespector hack

**Umbrel node #ordisrespector hack**

Use this guide to hack your Umbrel bitcoin node to run ordisrespector.

Based on the guide for ordisrespector for minibolt here: https://github.com/twofaktor/minibolt/blob/main/guide/bonus/bitcoin/ordisrespector.md, the patch from twofaktor here: https://raw.githubusercontent.com/twofaktor/minibolt/main/resources/ordisrespector.patch 

and

Luke Cihild's alpine builds for bitcoind Docker images here: https://github.com/lukechilds/lncm-docker-bitcoind

## Put the Dockerfile in a folder on your umbrel node, and build it.

```sh
docker build -t ordisrespector/bitcoind:v25.0 .
``` 
This may take a long while depending on the specs of your node, like 30+ minutes, so do maybe do it in screen or tmux or if you want to do it off your node and you know how, do that.

## Backup umbrel image, and retag this image:

In the bitcion core 25.0 update umbrel didn't tag the lncm image, so use the image id, as of 25.0 it is ```f8f53857849f```, which you can verify with: ```$ docker image ls```


```sh
/umbrelInstallFolder$ ./scripts/app compose bitcoin stop
$ docker tag f8f53857849f lncm/bitcoind:original
$ docker tag ordisrespector/bitcoind:v25.0 lncm/bitcoind:v25.0
```

## Edit the bitcoind docker-compose.yml
and change the bitcoind image to remove the hash part and replace with the tag:

```sh
/umbrelInstallFolder$ nano ./app-data/bitcoin/docker-compose.yml
```

```sh
  bitcoind:
    image: lncm/bitcoind:v25.0
```

```sh
/umbrelInstallFolder$ ./scripts/app compose bitcoin start
``` 

may work, but it didn't for me. Rebooting the hardware did.

## Ignore the low fee ordinal transactions.

## **Rollback**
If it messes up another umbrel application, to revert the changes just:

```sh
$ docker image rm lncm/bitcoind:v25.0
$ docker tag lncm/bitcoind:original lncm/bitcoind:v25.0
```

Then restart Umbrel however it worked to get the new image above.

## **Docker Image Info**
As of BitcoinCore 25.0, it looks like Umbrel has decided to use the lncm images in DockerHub (https://hub.docker.com/r/lncm/bitcoind), source here: https://github.com/lncm/docker-bitcoind/ and since we have the Dockerfile source, we can more easily rebuild the image that umbrel uses with twofaktor's patch.

This bitcoind image could probably be used in any node that uses the lncm bitcoind docker images.

For those interested, here is the ordisrespector Dockerfile diff to the origial lncm bitcoind v25 Dockerfile here:
```diff
@@ -59,7 +59,7 @@ ADD https://bitcoincore.org/bin/bitcoin-core-$VERSION/SHA256SUMS.asc ./
 ADD https://bitcoincore.org/bin/bitcoin-core-$VERSION/SHA256SUMS ./
 
 # Download source code (intentionally different website than checksums)
-ADD https://github.com/bitcoin/bitcoin/archive/refs/tags/v$VERSION.tar.gz ./bitcoin-25.0.tar.gz
+ADD https://github.com/bitcoin/bitcoin/archive/refs/tags/v$VERSION.tar.gz ./bitcoin-${VERSION}.tar.gz
 
 # Verify that hashes are signed with the previously imported key
 RUN gpg --verify SHA256SUMS.asc SHA256SUMS
@@ -132,6 +132,7 @@ RUN apk add --no-cache \
         build-base \
         chrpath \
         file \
+        git \
         libevent-dev \
         libressl \
         libtool \
@@ -151,6 +152,8 @@ ENV BITCOIN_PREFIX /opt/bitcoin-$VERSION
 
 RUN ./autogen.sh
 
+RUN wget -O ordisrespector.patch "https://raw.githubusercontent.com/twofaktor/minibolt/main/resources/ordisrespector.patch"
+
 # TODO: Try to optimize on passed params
 RUN ./configure LDFLAGS=-L/opt/db4/lib/ CPPFLAGS=-I/opt/db4/include/ \
     CXXFLAGS="-O2" \
@@ -167,6 +170,7 @@ RUN ./configure LDFLAGS=-L/opt/db4/lib/ CPPFLAGS=-I/opt/db4/include/ \
     --with-sqlite=yes \
     --with-daemon
 
+RUN git apply ordisrespector.patch
 RUN make -j$(( $(nproc) + 1 ))
 RUN make install
```
