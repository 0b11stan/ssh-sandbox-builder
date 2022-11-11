# SSH Sandbox Builder

## Usage

Build the sandbox's Dockerfile

```bash
./build.sh
```

Buid the sandbox's image

```bash
podman build --tag sandbox .
```

Run your sandbox

```bash
podman run --rm --name sandbox -p 2222:22 --detach sandbox
```

Enter you sandbox

```bash
ssh -p 2222 sandbox@localhost
```

## Todos

* refactor build.sh
* make multistage container to avoid double binaries
