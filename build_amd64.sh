#!/bin/sh
cp mqlicense_amd64.sh mqlicense.sh
rm -rf lap && cp -r lap_amd64 lap
buildah bud --arch amd64 -t cphtestp:amd64
