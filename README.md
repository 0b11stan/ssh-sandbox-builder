# SSH Sandbox Builder

## Usage

The `./ssb.sh` script create a default sandbox where you can only use `ls` in a
strongly stripped readonly filesystem. As is, the sandbox is secure but not of
much use. You must set environment variables to change the script behaviour.

```txt
Usage: ./ssb.sh

The following environment variables can be set to customize the sandbox:

  SSB_PACKAGES  list of alpine packages that will be installed
  SSB_CTRTECH   either docker or podman (default: podman)
  SSB_BINARIES  list of bins that will be made available (default: sh ls)
  SSB_EXTRA     list of files that will be made available (/etc/resolv.conf)
```

For exemple, you can run the following to describe a sandbox where only the
`ncat` command (from `nmap` project) will be available.

```bash
SSB_PACKAGES="nmap-ncat" SSB_BINARIES="sh ls ncat" ./ssb.sh > Dockerfile
```

You can now build the sandbox's image providing a username and a password for
the ssh user.

```bash
podman build \
  --build-arg "USERNAME=sampleuser" \
  --build-arg "PASSWORD=samplepass" \
  --tag sandbox .
```

Run your sandbox.

```bash
podman run --rm --name sandbox --publish 2222:22 --detach sandbox
```

Enter your sandbox.

```bash
ssh -p 2222 sampleuser@localhost
```

## Dev

Use the [Makefile](./Makefile).

What is the script doing:

1. starting a disposable build container (`prepare_container`)
2. installing all necessary packages in this container (`prepare_container`)
3. for all the needed binaries: identify dependancies using `ldd` (`extract_libs`)
4. write a dockerfile that contains an ssh with chroot feature configured
5. add all the cp commands to map the needed binaries and all their dependancies in the chroot environment (`write_*`)
