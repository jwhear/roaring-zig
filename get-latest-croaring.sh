#!/bin/bash
# The amalgamation repo hasn't been updated in a while.  Fortunately it's easy
#  to build yourself.
set -eou pipefail

repo="/tmp/CRoaring"

git clone --depth 1 https://github.com/RoaringBitmap/CRoaring.git $repo
rm -rf $repo/.git
cd croaring
$repo/amalgamation.sh

# clean up
cd -
rm -rf $repo
