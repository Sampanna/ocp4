#!/usr/bin/env bash
###############################################################
#
# Copyright (C) 2022 James Fuller, <jim@webcomposite.com>, et al.
#
# SPDX-License-Identifier: curl-docker
###############################################################
#
# ex.
#   > create_base_image.sh {arch} {dist} {builder image} {deps} {resultant_image_name}
#
#

echo "####### creating curl base image."

# set defaults
SO_NAME="libcurl.so.4.8.0"
PLATFORM_DEFAULT=""
DIST_DEFAULT="registry.hub.docker.com/library/alpine:latest"
BUILDER_DIST_DEFAULT="localhost/curl-dev"
DEPS_DEFAULT="brotli brotli-dev libssh2 nghttp2-dev"
IMAGE_NAME_DEFAULT="curl-base"

# get invoke opts
platform=${1:-$PLATFORM_DEFAULT}
dist=${2:-$DIST_DEFAULT}
builder_dist=${3:-$BUILDER_DIST_DEFAULT}
deps=${4:-$DEPS_DEFAULT}
image_name=${5:-$IMAGE_NAME_DEFAULT}

# set base and platform
if [[ -n $platform ]]; then
  echo "creating with platform=${platform}"
  ctr=$(buildah --arch ${platform} from ${dist})
else
  echo "creating ..."
  ctr=$(buildah from ${dist})
fi
ctrmnt=$(buildah mount $ctr)

# label/env
buildah config --label maintainer="James Fuller <jim.fuller@webcomposite.com>" $ctr
buildah config --label name="${IMAGE_NAME_DEFAULT}" $ctr
buildah config --label version="${release_tag}" $ctr
buildah config --label docker.cmd="podman run -it ${IMAGE_NAME_DEFAULT}:${release_tag}" $ctr

# determine dist package manager
if [[ "$dist" =~ .*"alpine".* ]]; then
  package_manage_update="apk update upgrade"
  package_manage_add="apk add --no-cache "
fi
if [[ "$dist" =~ .*"fedora".* ]]; then
  package_manage_update="dnf update upgrade"
  package_manage_add="dnf add"
fi
if [[ "$dist" =~ .*"debian".* ]]; then
  package_manage_update="deb update upgrade"
  package_manage_add="deb add"
fi

# deps
buildah run $ctr ${package_manage_update}
buildah run $ctr ${package_manage_add} ${deps}

# mount dev image containing build artifacts
bdr=$(buildah from ${builder_dist})
bdrmnt=$(buildah mount $bdr)

# copy build artifacts
cp $bdrmnt/build/usr/local/bin/curl $ctrmnt/usr/bin/curl
cp -r $bdrmnt/build/usr/local/include/curl $ctrmnt/usr/include/curl
cp -r $bdrmnt/build/usr/local/lib/* $ctrmnt/usr/lib/.

# link
buildah run $ctr rm /usr/lib/libcurl.so.4 /usr/lib/libcurl.so
buildah run $ctr ln -s /usr/lib/${SO_NAME} /usr/lib/libcurl.so.4
buildah run $ctr ln -s /usr/lib/libcurl.so.4 /usr/lib/libcurl.so

# set ca bundle
buildah run $ctr curl https://curl.haxx.se/ca/cacert.pem -L -o /cacert.pem
buildah config --env CURL_CA_BUNDLE="/cacert.pem" $ctr

# setup curl_group and curl_user though it is not used
buildah run $ctr addgroup -S curl_group
buildah run $ctr adduser -S curl_user -G curl_group

# set entrypoint
buildah config --cmd curl $ctr
buildah copy --chmod 700 --chown curl_user:curl_group $ctr etc/entrypoint.sh /entrypoint.sh
buildah config --entrypoint '["/entrypoint.sh"]' $ctr

# commit image
buildah commit $ctr "${image_name}" # --disable-compression false --squash --sign-by --tls-verify
