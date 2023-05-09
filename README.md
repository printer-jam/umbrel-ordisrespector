# Umbrel Bitcoin Node #ordisrespector hack

**Umbrel node #ordisrespector hack**

Use this guide to hack your Umbrel bitcoin node to run ordisrespector. 

Based on the guide for ordisrespector for minibolt here: https://github.com/twofaktor/minibolt/blob/main/guide/bonus/bitcoin/ordisrespector.md, the patch from twofaktor here: https://raw.githubusercontent.com/twofaktor/minibolt/main/resources/ordisrespector.patch 

and

Luke Cihild's alpine builds for bitcoind Docker images here: https://github.com/lukechilds/lncm-docker-bitcoind

We simply build the disrespector binaries of bitcoin in the same base alpine image as Umbrel's bitcoind image, and then copy over the binary files to the Umbrel image, and use that modified image in Umbrel's docker-compose. 

Reasoning is I have no idea what is Umbrel's image config, and I don't really want to reverse engineer it, just have it run ordisrespector bitcoind. I copied over the other binaries as well, cli, tx, utils, wallet, not sure if they were needed.

So, do so at your own risk, this may break other apps that rely on an unmodified bitcoin core, I may have messed up the berkley DB thing or not, it seems ok for my node.


## Put the Dockerfile in a folder on your umbrel node, and build it.

```sh
docker build -t ordisrespector/bitcoind:v24.0.1 .
``` 
This may take a long while depending on the specs of your node, like 30+ minutes, so do maybe do it in screen or tmux or if you want to do it off your node and you know how, do that.

## Backup umbrel image, and retag this image:

```sh
/umbrelInstallFolder$ ./scripts/app compose bitcoin stop
$ docker tag getumbrel/bitcoind:v24.0.1 getumbrel/bitcoind:original
$ docker tag ordisrespector/bitcoind:v24.0.1 getumbrel/bitcoind:v24.0.1
```

## Edit the bitcoind docker-compose.yml
and change the bitcoind image to remove the hash part and replace with the tag:

```sh
/umbrelInstallFolder$ nano ./app-data/bitcoin/docker-compose.yml
```

```sh
  bitcoind:
    image: getumbrel/bitcoind:v24.0.1
```

```sh
/umbrelInstallFolder$ ./scripts/app compose bitcoin start
``` 

may work, but it didn't for me. Rebooting the hardware did.

## Ignore the low fee ordinal transactions.

## **Rollback**
If it messes up another umbrel application, to revert the changes just:

```sh
$ docker image rm getumbrel/bitcoind:v24.0.1
$ docker tag getumbrel/bitcoind:original getumbrel/bitcoind:v24.0.1
```

Then restart Umbrel however it worked to get the new image above.
