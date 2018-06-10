#!/usr/bin/env bash

set -x

OUTPUT_DIR=$(pwd)/"output"

BASE_IMAGE=${1:-aarch64/debian:jessie}
DOCKER_IMAGE="docker-builder"
DOCKER_VERSION="18.05.0-ce"

docker build -t "${DOCKER_IMAGE}" - <<EOF

FROM ${BASE_IMAGE}

RUN set -xe \
    && apt-get update && apt-get install -y --no-install-recommends\
       make \
       git \
       ca-certificates \
       xz-utils \
       libltdl7 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EOF

[ -d "${OUTPUT_DIR}" ] && { rm -fr "${OUTPUT_DIR}" || exit 1 ; }
mkdir -p "${OUTPUT_DIR}" || exit 1

docker run -i --rm \
           -v /usr/bin/docker:/usr/bin/docker \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -v "${OUTPUT_DIR}":"${OUTPUT_DIR}" \
       "${DOCKER_IMAGE}" bash -s <<EOF

set -x

cd ${OUTPUT_DIR}
git clone --depth 1 --branch v${DOCKER_VERSION} --single-branch https://github.com/docker/docker.git

cd docker
make build
make binary

EOF

cd "${OUTPUT_DIR}/docker"
tar -cJhvf ../docker.tar.xz --xform='s,bundles/binary-daemon,.,g' bundles/binary-daemon/docker-containerd bundles/binary-daemon/docker-containerd-ctr bundles/binary-daemon/docker-containerd-shim bundles/binary-daemon/dockerd bundles/binary-daemon/docker-init bundles/binary-daemon/docker-proxy bundles/binary-daemon/docker-runc
cd -
