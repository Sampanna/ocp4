# Curl docker

**WORKING ON - multiarch, labels, release CI/test/push to docker hub**

This repository defines the official curl docker images which are available from the following registries:
* [hub.docker.com](https://hub.docker.com/r/curlimages/curl): official images
* [github packages](https://github.com/orgs/curl/packages): development images

To pull an image:
```
> {docker|podman} pull curlimages/curl:latest
```
To run an image:
```
> {docker|podman} run -it curlimages/curl:latest -V
```

Images are signed using [sigstore](https://www.sigstore.dev/). To verify an image install 
sigstore cosign utility and use [cosign.pub](cosign.pub) public key:
```
> cosign verify --key cosign.pub ghcr.io/curl/curl-docker/curl:master
```

**Note**- you need to login to container registry first before pulling it, ex. `{podman|docker} logon {registry}`.

## Contact

If you have problems, questions, ideas or suggestions, please [raise an issue](https://github.com/curl/curl-docker/issues) or contact [curl-docker team](curl-docker@haxx.se)
or [Jim Fuller](jim.fuller@webcomposite.com) directly.

## Images

### Official curl images
The official curl images are based on alpine and made available via docker hub (docker.io) et al.
* **curlimages/curl:latest** - latest curl tag release with alpine base (multiarch)
* **curlimages/curl:#.#.#** - specific curl tag release with alpine base (multiarch)

Base images are also provided.
* **curlimages/curl-base:latest** - use to build your own images based on latest curl tag release with alpine base (multiarch)
* **curlimages/curl-base:#.#.#** - use to build your own images based on specific curl tag release with alpine base (multiarch)

for example;
```
from curlimages/curl-base:latest
RUN apk add jq
```

### Development curl images

The following images are available via [github packages](https://github.com/orgs/curl/packages).

Master branch built hourly:
* **curl-dev:master** - curl-dev **master** branch built hourly
* **curl-base:master** - curl-base **master** branch built hourly
* **curl:master** - curl **master** branch built hourly

A set of special case images built daily:
* **curl-exp:master** - curl **master** branch built enabling expiremental features

Platform specific dev images built daily:
* **curl-dev-debian:master** - debian based development environment
* **curl-dev-ubuntu:master** - ubuntu based development environment
* **curl-dev-fedora:master** - fedora based development environment

for example; 
```
> {docker|podman} run -v /src/my-curl-src:/src/curl curlimages/curl-dev-alpine:latest /bin/sh
$> cd /src/curl
$> ./configure
```

## Generating custom dev images
Create your own custom dev image using the `build_ref_images` Makefile target, passing in `branch_or_tag` and `release_tag` vars:
```commandline
> make branch_or_ref=curl-master release_tag=master build_ref_images
```
Alternately you can directly invoke create_dev_image.sh which gives a bit more configuration options.
```
 > create_dev_image.sh {arch} {base image} {compiler} {deps} {build_opts} {branch_or_tag} {resultant_image_name}
```
where the input supplied defines the type of image built.
* arch: `linux/arm`
* base image: `registry.hub.docker.com/library/alpine:latest`
* compiler: `gcc`
* deps: `ssh2 libssh2-dev libssh2-static autoconf automake build-base groff openssl curl-dev python3 python3-dev libtool curl stunnel perl nghttp2 brotli brotli-dev`
* build_opts: `--enable-static --disable-ldap --enable-ipv6 --enable-unix-sockets --with-ssl --with-libssh2 --with-nghttp2=/usr`
* branch_or_tag: `master`
* resultant_image_name: `my_curl_dev_image`

for example;
```commandline
> ./create_dev_image.sh "linux/amd64" alpine:latest gcc \
      "libssh2 libssh2-dev libssh2-static autoconf automake build-base groff openssl curl-dev python3 python3-dev libtool curl stunnel perl nghttp2 brotli brotli-dev" \
      " --enable-static --disable-ldap --enable-ipv6 --enable-unix-sockets --with-ssl --with-libssh2 --with-nghttp2=/usr" \
      master my_curl_dev_image
```
## Dependencies

Either of the following are required to use images:
* [podman](https://podman.io/getting-started/) 
* [docker](https://docs.docker.com/get-docker/)

The following are required to build or release images: 
* [buildah](https://buildah.io/): used for composing dev/build images
* [qemu-user-static](https://github.com/multiarch/qemu-user-static): used for building multiarch images

**Note**- unfortunately buildah is not (yet) available for Apple/OSX.

## Release management

TBA

## Points of Interest

There is a hierarchy of images which are used to derive the final curl image.
```
  curl-dev image 
               |---(copy artifacts)---> 
                                      curl-base image 
                                                    |---(from)---> curl image
```
which is analagous to multistage builds.

* curl-dev provides an 'instant' development environment
* curl-base images only copy build artifacts from curl-dev
* curl image inherits from curl-base adding user (curl_user) constraint

