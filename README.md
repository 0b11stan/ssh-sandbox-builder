# SSH Sandbox Builder

## Usage

Modify variables at the start of `build.sh` then run the script.

```bash
./build.sh
```

You can now build the sandbox's image:

```bash
podman build \
  --build-arg "USERNAME=sandboxuser" \
  --build-arg "PASSWORD=sandboxpassword" \
  --tag sandbox .
```

Run your sandbox

```bash
podman run --rm --name sandbox --publish 2222:22 --detach sandbox
```

Enter you sandbox

```bash
ssh -p 2222 sandbox@localhost
```

## Todos

* make multistage container to avoid double binaries
* find a nice sandalone way to remove username:password from build arg
