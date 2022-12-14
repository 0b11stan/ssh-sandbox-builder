test "$#" -ge 1 && { cat > /dev/stdout <<EOF
Usage: $0

The following environment variables can be set to customize the sandbox:

  SSB_BINARIES    list of bins that will be made available (default: sh ls)
  SSB_PACKAGES    list of alpine packages that will be installed
  SSB_CTRTECH     either docker or podman (default: podman)
  SSB_EXTRA       list of files that will be made available (/etc/resolv.conf)
  SSB_HOME        home directory of the ssh user (default: /sandbox)
  SSB_DOCKERFILE  provide your own base dockerfile (default is built in)
EOF
exit; }

find_default_container_tech() {
  podman --version &> /dev/null && echo "podman" && return 0
  docker --version &> /dev/null && echo "docker" && return 0
  echo "ERROR: you need at least one of docker or podman installed" && exit 1
}

CTR_DEFAULT=$(find_default_container_tech)

PACKAGES=$SSB_PACKAGES
CTRTECH=$(test -z "$SSB_CTRTECH" && echo "$CTR_DEFAULT" || echo "$SSB_CTRTECH")
BINARIES=$(test -z "$SSB_BINARIES" && echo "sh ls" || echo "$SSB_BINARIES")
EXTRA=$(test -z "$SSB_EXTRA" && echo "/etc/resolv.conf" || echo "$SSB_EXTRA")
SSB_HOME=$(test -z "$SSB_HOME" && echo "sandbox" || echo "$SSB_HOME")
DOCKERFILE=$SSB_DOCKERFILE

CONTAINER_NAME=ssh-sandbox-builder

container_execute() {
  $CTRTECH exec $CONTAINER_NAME /bin/sh -c "$1"
}

prepare_container() {
  $CTRTECH run --detach --rm --name $CONTAINER_NAME alpine sh -c \
    'while true; do sleep 1000; done' > /dev/null
  container_execute "apk add $PACKAGES" > /dev/null
}

destroy_container() {
  $CTRTECH stop --time 1 $CONTAINER_NAME &> /dev/null
  $CTRTECH rm $CONTAINER_NAME &> /dev/null
}

extract_libs() {
  for app in $1; do
    container_execute "ldd $app" 
  done | sed 's!^[^/]*\(/[^ ]*\) .*!\1!' | sort -u
}

write_package_installations() {
  echo "RUN apk add $1" >> /dev/stdout
}

write_directory_creations() {
  echo "RUN mkdir -p $(dirname $1 | sort -u | tr "\n" ' ')" \
    | sed 's! /! /chroot/!g' >> /dev/stdout
}

write_file_copies_to_chroot() {
  echo -n $1 | tr ' ' '\0' \
    | xargs --null -I '{}' echo 'RUN cp {} /chroot{}' >> /dev/stdout
}

write_path_modification() {
  echo "ENV PATH=$(echo $1 | tr ' ' ':')" >> /dev/stdout
}

prepare_container

BINARIES=$(container_execute "which $BINARIES")
LIBS=$(extract_libs "$BINARIES")
FILES=$(echo "$LIBS $BINARIES $EXTRA" | tr ' ' "\n" | sort -u)

test -n "$DOCKERFILE" && cat $DOCKERFILE > /dev/stdout \
  || cat > /dev/stdout <<EOF
FROM alpine
ARG USERNAME=sandbox
ARG PASSWORD=changeme

# install openssh
RUN apk add openssh
RUN echo -e '\
AllowAgentForwarding no\n\
AllowTcpForwarding no\n\
AuthorizedKeysFile .ssh/authorized_keys\n\
ChrootDirectory /chroot\n\
GatewayPorts no\n\
PasswordAuthentication yes\n\
PermitEmptyPasswords no\n\
PermitRootLogin no\n\
PermitTunnel no\n\
X11Forwarding no\n\
' > /etc/ssh/sshd_config
RUN /usr/bin/ssh-keygen -A

# add secure user
RUN adduser -s /bin/sh --disabled-password -H -h /$SSB_HOME \$USERNAME
RUN echo \$USERNAME:\$PASSWORD > /root/pass.txt \
  && chpasswd < /root/pass.txt \
  && rm /root/pass.txt

WORKDIR /chroot/$SSB_HOME
CMD /usr/sbin/sshd -D
EOF

echo -e "\n# autogenerated by SSH Sandbox Builder" >> /dev/stdout

write_package_installations "$PACKAGES"
write_directory_creations "$FILES"
write_file_copies_to_chroot "$FILES"
write_path_modification "$BINARIES"

destroy_container
