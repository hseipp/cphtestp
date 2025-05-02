#!/bin/sh
cp mqlicense_s390x.sh mqlicense.sh
rm -rf lap && cp -r lap_s390x lap
buildah bud --platform=linux/s390x --network slirp4netns:enable_ipv6=false -t cphtestp:s390x
