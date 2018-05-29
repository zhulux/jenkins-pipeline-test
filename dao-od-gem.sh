#!/usr/bin/env bash
# build and push gem to private hosting server
# NOTE: running in a standalone ruby container in CI process!

ls
pwd
id
ls /
echo "-----"
ls -la ~
ls -la /root
echo ":push-key: $PUSH_KEY" > /root/.gem/credentials
chmod 600 /root/.gem/credentials
cd optimus_data
echo $PUSH_KEY
echo $GEM_SERVER

# just triggered by tags: od-66.xx.xx
version=$(echo $DAO_COMMIT_TAG | cut -d - -f 2)
echo ==parsed od gem version: $version
export OD_GEM_BUILD_VERSION=$version 
gem build optimus_data.gemspec

gem push optimus_data-*.gem --host "$GEM_SERVER" --key push-key -V
echo Congrats $version gem pushed!
