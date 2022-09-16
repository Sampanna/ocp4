.DEFAULT_GOAL := all

container_ids=`buildah ls --format "{{.ContainerID}}"`

base=alpine:3.15.4
arch=""
compiler="gcc"
build_opts=" --enable-static --disable-ldap --enable-ipv6 --enable-unix-sockets --with-ssl --with-libssh2 --with-nghttp2=/usr"
dev_deps="libssh2 libssh2-dev libssh2-static autoconf automake build-base groff openssl curl-dev python3 python3-dev libtool curl stunnel perl nghttp2 brotli brotli-dev"
base_deps="brotli brotli-dev libssh2 nghttp2-dev"
arches="linux/arm/v7,linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386"

#############################
# build_ref_images
#############################
#
#  > make branch_or_ref=master release_tag=master build_ref_images
#
build_ref_images:
	buildah unshare ./create_dev_image.sh ${arch} ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev:${release_tag}
	buildah unshare ./create_base_image.sh ${arch} ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base:${release_tag}
	./create_appliance_image.sh ${arch} localhost/curl-base:${release_tag} curl:${release_tag}

#############################
# test
#############################
#
#  > make branch_or_ref=master test
#
test:
	buildah unshare tests/test_image.sh ${release_tag}

#############################
# scan
#############################
#
#  > make release_tag=master scan
#
scan:
	systemctl --user enable --now podman.socket
	curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo bash -s -- -b /usr/local/bin v0.32.0
	trivy image localhost/curl:${release_tag}
#	wget -qO - https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo bash -s -- -b /usr/local/bin
#	grype curl:${release_tag}

multibuild:
	buildah unshare ./create_dev_image.sh linux/amd64 ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev-linux-amd64:${release_tag}
	buildah unshare ./create_base_image.sh linux/amd64 ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base-linux-amd64:${release_tag}
	./create_appliance_image.sh linux/amd64 localhost/curl-base:${release_tag} curl-linux-amd64:${release_tag}

	buildah unshare ./create_dev_image.sh linux/arm/v7 ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev-linux-arm-v7:${release_tag}
	buildah unshare ./create_base_image.sh linux/arm/v7 ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base-linux-arm-v7:${release_tag}
	./create_appliance_image.sh linux/arm/v7 localhost/curl-base:${release_tag} curl-linux-arm-v7:${release_tag}

	buildah unshare ./create_dev_image.sh "linux/arm64" ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev-linux-arm64:${release_tag}
	buildah unshare ./create_base_image.sh "linux/arm64" ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base-linux-arm64:${release_tag}
	./create_appliance_image.sh "linux/arm64" localhost/curl-base:${release_tag} curl-linux-arm64:${release_tag}

# 	buildah unshare ./create_dev_image.sh linux/ppc64le ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev-linux-ppc64le:${release_tag}
# 	buildah unshare ./create_base_image.sh linux/ppc64le ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base-linux-ppc64le:${release_tag}
# 	./create_appliance_image.sh linux/ppc64le localhost/curl-base:${release_tag} curl-linux-ppc64le:${release_tag}
#
# 	buildah unshare ./create_dev_image.sh linux/s390x ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev-linux-s390x:${release_tag}
# 	buildah unshare ./create_base_image.sh linux/s390x ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base-linux-s390x:${release_tag}
# 	./create_appliance_image.sh linux/s390x localhost/curl-base:${release_tag} curl-linux-s390x:${release_tag}
#
# 	buildah unshare ./create_dev_image.sh linux/386 ${base} ${compiler} ${dev_deps} ${build_opts} ${branch_or_ref} curl-dev-linux-386:${release_tag}
# 	buildah unshare ./create_base_image.sh linux/386 ${base} localhost/curl-dev:${release_tag} ${base_deps} curl-base-linux-386::${release_tag}
# 	./create_appliance_image.sh linux/386 localhost/curl-base:${release_tag} curl-linux-386::${release_tag}

#############################
# utilities
#############################
#
#
buildah_clean:
	buildah rm $(container_ids)
run_curl_dev_master:
	# assumes git checkout of curl at ../curl
	podman run -it -v ../curl:/src/curl:z localhost/curl-dev:master
run_curl_base_master:
	# assumes git checkout of curl at ../curl
	podman run -it -v ../curl:/src/curl:z localhost/curl-base:master
run_curl_master:
	# assumes git checkout of curl at ../curl
	podman run -it -v ../curl:/src/curl:z localhost/curl:master


