#!/usr/bin/env bash
###############################################################
#
# Copyright (C) 2022 James Fuller, <jim@webcomposite.com>, et al.
#
# SPDX-License-Identifier: curl-docker
###############################################################
#
# ex.
#   > create_dev_image.sh {arch} {base image} {compiler} {deps} {build_opts} {branch or tag} {resultant_image_name}
#
#

echo "####### creating curl dev image."

# set defaults matching alpine release image
test_flag=0
PLATFORM_DEFAULT=""
DIST_DEFAULT="registry.hub.docker.com/library/alpine:latest"
COMPILER_DEPS_DEFAULT="gcc"
DEPS_DEFAULT="libssh2 libssh2-dev libssh2-static autoconf automake build-base groff openssl curl-dev python3 python3-dev libtool curl stunnel perl nghttp2 brotli brotli-dev"
BUILD_OPTS_DEFAULT=" --enable-static --disable-ldap --enable-ipv6 --enable-unix-sockets --with-ssl --with-libssh2 --with-nghttp2=/usr"
BRANCH_OR_TAG_DEFAULT="master"
IMAGE_NAME_DEFAULT="curl-dev-alpine"

# get invoke opts
platform=${1:-$PLATFORM_DEFAULT}
dist=${2:-$DIST_DEFAULT}
compiler_deps=${3:-$COMPILER_DEPS_DEFAULT}
deps=${4:-$DEPS_DEFAULT}
build_opts=${5:-$BUILD_OPTS_DEFAULT }
branch_or_tag=${6:-$BRANCH_OR_TAG_DEFAULT}
image_name=${7:-$IMAGE_NAME_DEFAULT}

# set base and platform
if [[ -n $platform ]]; then
  echo "creating with platform=${platform}"
  bdr=$(buildah --arch ${platform} from ${dist})
else
  echo "creating ..."
  bdr=$(buildah from ${dist})
fi

# label/env
buildah config --label maintainer="James Fuller <jim.fuller@webcomposite.com>" $ctr
buildah config --label name="${IMAGE_NAME_DEFAULT}" $ctr
buildah config --label version="${release_tag}" $ctr
buildah config --label docker.cmd="podman run -it ${IMAGE_NAME_DEFAULT}:${release_tag}" $ctr

#buildah inspect $bdr

# determine dist package manager
if [[ "$dist" =~ .*"alpine".* ]]; then
  package_manage_update="apk update upgrade"
  package_manage_add="apk add "
fi
if [[ "$dist" =~ .*"fedora".* ]]; then
  package_manage_update="dnf update upgrade"
  package_manage_add="dnf add"
fi
if [[ "$dist" =~ .*"debian".* ]]; then
  package_manage_update="deb update upgrade"
  package_manage_add="deb add"
fi

# install deps using specific dist package manager
echo $install_deps
buildah run $bdr ${package_manage_update}
buildah run $bdr ${package_manage_add} ${deps}

# setup curl source derived from branch or tag
buildah run $bdr mkdir /src
buildah run $bdr curl -L -o curl.tar.gz https://github.com/curl/curl/archive/${branch_or_tag}.tar.gz
buildah run $bdr tar -xvf curl.tar.gz
buildah run $bdr rm curl.tar.gz
buildah run $bdr mv curl-${branch_or_tag} /src/curl-${branch_or_tag}
buildah config --workingdir /src/curl-${branch_or_tag} $bdr

# build curl
buildah run $bdr ./buildconf
buildah run $bdr autoreconf -vif
buildah run $bdr ./configure ${build_opts}
buildah run $bdr make -j$(nproc)

# run tests
if [[ $test_flag == 1 ]]; then
  buildah run $bdr make test
fi

# install curl
buildah run $bdr make DESTDIR="/build/" install  -j$(nproc)

# commit image
buildah commit $bdr "${image_name}" # --disable-compression false --squash --sign-by --tls-verify

# set base and platform
if [[ -n $platform ]]; then
  echo "creating with platform=${platform}"
  ctr=$(buildah --arch ${platform} from ${dist})
else
  echo "creating ..."
  ctr=$(buildah from ${dist})
fi

mnt=$(buildah mount $bdr)

# report
echo "${image_name} created build with:"
echo "   base: ${dist}"
echo "   deps: ${deps}"
echo "   build_opts: ${build_opts}"
echo "   branch/tag: ${branch_or_tag}"
echo "artifacts installed at /build/usr/local"
