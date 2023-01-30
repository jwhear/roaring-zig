#!/bin/bash
# The amalgamation repo hasn't been updated in a while.  Fortunately it's easy
#  to build yourself.
set -eou pipefail

repo="/tmp/CRoaring"

git clone https://github.com/RoaringBitmap/CRoaring.git $repo
cd croaring
$repo/amalgamation.sh

# clean up
cd -
rm -rf $repo
