all: ssh

Dockerfile:
	. ./ssb.sh

image: Dockerfile
	podman build \
		--build-arg "USERNAME=sampleuser" \
		--build-arg "PASSWORD=samplepassword" \
		--tag sandbox .

run: image
	podman run --rm --name sandbox -p 2222:22 --detach sandbox

ssh: run
	ssh -o 'StrictHostKeyChecking accept-new' -p 2222 sandbox@localhost

exec:
	podman exec -it sandbox /bin/sh

clean:
	sed -i '/^\[localhost\].*/d' ~/.ssh/known_hosts
	-podman stop sandbox
	-podman rm sandbox
	-rm Dockerfile
