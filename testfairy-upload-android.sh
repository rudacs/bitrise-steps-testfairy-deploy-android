#!/bin/sh

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# load bash utils
source "${THIS_SCRIPT_DIR}/bash_utils/formatted_output.sh"

UPLOADER_VERSION=1.09

# Tester Groups that will be notified when the app is ready. Setup groups in your TestFairy account testers page.
# This parameter is optional, leave empty if not required
TESTER_GROUPS="$tester_groups"

# Should email testers about new version. Set to "off" to disable email notifications.
NOTIFY="$notify"

# If AUTO_UPDATE is "on" all users will be prompt to update to this build next time they run the app
AUTO_UPDATE="$auto_update"

# The maximum recording duration for every test. 
MAX_DURATION="$max_test_duration"

# Is video recording enabled for this build 
VIDEO="$video_recording"

# Add a TestFairy watermark to the application icon?
ICON_WATERMARK="$icon_watermark"

# Comment text will be included in the email sent to testers
COMMENT="$comment"

# locations of various tools
CURL=curl

SERVER_ENDPOINT=http://app.testfairy.com

usage() {
	echo "Usage: testfairy-upload-android.sh APK_FILENAME"
	echo
}

verify_settings() {
	if [ -z "${api_key}" ]; then
		usage
		echo "Please update API_KEY with your private API key, as noted in the Settings page"
		exit 1
	fi
}

if [ $# -ne 1 ]; then
	usage
	exit 1
fi

# before even going on, make sure all tools work
verify_settings

APK_FILENAME=$1
if [ ! -f "${APK_FILENAME}" ]; then
	usage
	echo "Can't find file: ${APK_FILENAME}"
	exit 2
fi

/bin/echo -n "Uploading ${APK_FILENAME} to TestFairy.. "
JSON=$( "${CURL}" -s ${SERVER_ENDPOINT}/api/upload -F api_key=${api_key} -F apk_file="@${APK_FILENAME}" -F icon-watermark="${ICON_WATERMARK}" -F testers-groups="${TESTER_GROUPS}" -F auto-update="${AUTO_UPDATE}" -F notify="${NOTIFY}" -F video="${VIDEO}" -F max-duration="${MAX_DURATION}" -F comment="${COMMENT}" -A "TestFairy Command Line Uploader ${UPLOADER_VERSION}" )

MESSAGE=$( echo ${JSON} | sed 's/\\\//\//g' | sed -n 's/.*"message"\s*:\s*"\([^"]*\)".*/\1/p' )
URL=$( echo ${JSON} | sed 's/\\\//\//g' | sed -n 's/.*"build_url"\s*:\s*"\([^"]*\)".*/\1/p' )

if [ ! -z "$MESSAGE" ]; then
	write_section_to_formatted_output "## Deploy Failed"
	echo_string_to_formatted_output "Failed to upload the build due to the following error:"
	echo_string_to_formatted_output "$MESSAGE"
	exit 1
elif [ -z "$URL" ]; then
	write_section_to_formatted_output "## Deploy Failed"
	echo_string_to_formatted_output "Build uploaded, but no reply from server. Please contact support@testfairy.com"
	exit 1
fi

write_section_to_formatted_output "## Deploy Success"
echo_string_to_formatted_output "* **Build URL**: [${URL}](${URL})"

envman add --key TESTFAIRY_PUBLIC_INSTALL_PAGE_URL_ANDROID --value "${URL}"

exit 0