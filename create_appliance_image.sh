#!/usr/bin/env bash
###############################################################
#
# Copyright (C) 2022 James Fuller, <jim@webcomposite.com>, et al.
#
# SPDX-License-Identifier: curl-docker
###############################################################
#
# ex.
#   > create_appliance_image.sh {arch} {dist} {base image} {resultant_image_name}
#
#

echo "####### creating curl image."

# set defaults
SO_NAME="libcurl.so.4.8.0"
PLATFORM_DEFAULT=""
BASE_DEFAULT="registry.hub.docker.com/library/alpine:latest"
IMAGE_NAME_DEFAULT="curl-base"

# get invoke opts
platform=${1:-$PLATFORM_DEFAULT}
base_dist=${2:-$BUILDER_DIST_DEFAULT}
image_name=${3:-$IMAGE_NAME_DEFAULT}

ctr=$(buildah from ${base_dist})

# label/env
buildah config --label maintainer="James Fuller <jim.fuller@webcomposite.com>" $ctr
buildah config --label name="${IMAGE_NAME_DEFAULT}" $ctr
buildah config --label version="${release_tag}" $ctr
buildah config --label docker.cmd="podman run -it ${IMAGE_NAME_DEFAULT}:${release_tag}" $ctr

# assumes base image has setup curl_user
buildah config --user curl_user $ctr

# commit image
buildah commit $ctr "${image_name}" # --disable-compression false --squash --sign-by --tls-verify
