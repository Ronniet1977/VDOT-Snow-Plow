#
//  ci_pre_xcodebuild.sh
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 10/12/26.
//

#!/bin/sh

set -e

echo "☁️ Xcode Cloud build number: $CI_BUILD_NUMBER"

cd "$CI_PRIMARY_REPOSITORY_PATH"

xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
