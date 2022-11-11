all: ssh

Dockerfile:
	. ./build.sh

image: Dockerfile
	podman build --tag sandbox .
	sed -i '/^\[localhost\].*/d' ~/.ssh/known_hosts

run: image
	-podman stop sandbox
	-podman rm sandbox
	podman run --rm --name sandbox -p 2222:22 --detach sandbox

ssh: run
	ssh -o 'StrictHostKeyChecking accept-new' -p 2222 sandbox@localhost

exec:
	podman exec -it sandbox /bin/sh

clean:
	-rm Dockerfile
