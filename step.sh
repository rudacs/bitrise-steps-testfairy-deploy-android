#!/bin/bash

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bash "${THIS_SCRIPTDIR}/testfairy-upload-android.sh" "$apk_path"
exit $?