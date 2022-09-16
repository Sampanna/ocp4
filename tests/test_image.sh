#!/usr/bin/env bash
###############################################################
#
# Copyright (C) 2022 James Fuller, <jim@webcomposite.com>, et al.
#
# SPDX-License-Identifier: curl-docker
###############################################################
#
# ex.
#   > test_image.sh {branch or tag}
#
#
# Copyright (C) 2022 Jim Fuller, <jim@webcomposite.com>, et al.
#
# SPDX-License-Identifier: curl-docker

echo "####### testing curl dev image."

# set defaults matching alpine release image
BRANCH_OR_TAG_DEFAULT="master"

# get invoke opts
branch_or_tag=${1:-$BRANCH_OR_TAG_DEFAULT}

# create and mount image
ctr=$(buildah from curl:${branch_or_tag})
ctrmnt=$(buildah mount $ctr)

# check file exists
if [[ ! -f "$ctrmnt/usr/bin/curl" ]]; then
    echo "/usr/bin/curl does not exist."
fi
if [[ ! -f "$ctrmnt/usr/lib/libcurl.so.4.8.0" ]]; then
    echo "/usr/lib/libcurl.so.4.8.0 does not exist."
fi

# check symlink exists and is not broken
if [ ! -L "$ctrmnt/usr/lib/libcurl.so.4" ] && [ ! -e "$ctrmnt/usr/lib/libcurl.so.4" ]; then
    echo "/usr/lib/libcurl.so.4 symlink does not exist or is broken."
fi
if [ ! -L "$ctrmnt/usr/lib/libcurl.so" ] && [ ! -e "$ctrmnt/usr/lib/libcurl.so"  ]; then
    echo "/usr/lib/libcurl.so symlink does not exist or is broken."
fi
# check CURL_CA_BUNDLE is set
buildah run $ctr test ${CURL_CA_BUNDLE}

# test running curl
buildah run $ctr /usr/bin/curl -V