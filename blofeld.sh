#!/bin/bash

readonly PROGNAME=$(basename $0)
AWS=aws
MIME=node_modules/.bin/mime

s3() {
	$AWS s3 "$@"
}

s3_create_bucket() {
	local bucket="$1"

	echo "Creating bucket $bucket"

	if s3 mb "s3://$bucket" > /dev/null; then
		echo "Bucket $bucket created"
	else
		echo "Bucket $bucket exists"
	fi
}

s3_setup_website() {
	local bucket="$1"

	echo "Setting up $bucket to serve websites"

	s3 website \
		"s3://$bucket" \
		--index-document index.html \
		--error-document 404.html 
}

deploy_short_expiry() {
	local bucket="$1"; shift
	local files=$@
	local f

	echo "Syncing short-expiry files $files to $bucket"

	for f in $files; do
		s3 cp \
			"$f" \
			"s3://$bucket/${f#$FOLDER/}" \
			--acl public-read --cache-control "max-age=600"
	done
}

deploy_gzip() {
	local bucket="$1"; shift
	local files=$@
	local f

	echo "Syncing gzipped files $files to $bucket"

	for f in $files; do
		local mime=$($MIME "$f")
		if [[ $SELF_GZIP ]]; then
			echo "Gzipping $f"
			local file=$(mktemp /tmp/.blofeld-XXXXXXX)
			gzip -9 $f -c > $file
		else
			local file=$f
		fi

		s3 cp \
			"$file" \
			"s3://$bucket/${f#$FOLDER/}" \
			--acl public-read \
			--cache-control "max-age=31536000" \
			--content-encoding gzip \
			--content-type "$mime"
	done
}

deploy_folder() {
	local bucket="$1"
	local folder="$2"

	echo "Syncing $folder to $bucket"

	s3 sync \
		"$folder" \
		"s3://$bucket" \
		--acl public-read \
		--cache-control "max-age=31536000" \
		--delete
}

usage() {
	echo "$PROGNAME -t target_bucket -f folder [-s short_expiry_files] [-g gziped_files]"
}

cmdline() {
	while getopts ":t:f:s:g:xhG" OPTION; do
		case $OPTION in
		x) set -x ;;
		t) readonly TARGET_BUCKET="$OPTARG" ;;
		f) readonly FOLDER="$OPTARG" ;;
		g) readonly GZIP_FILES="$OPTARG" ;;
		G) readonly SELF_GZIP=1 ;;
		s) readonly SHORT_EXPIRY="$OPTARG" ;;
		h) usage; exit 0 ;;
		\?) echo "Unknown option $OPTARG" ; usage ; exit 1 ;;
		\:) echo "$OPTARG requires an argument" ; exit 1 ;;
	esac; done
}

main() {
	cmdline "$@"

	[[ -z $TARGET_BUCKET || -z $FOLDER ]] && { usage ; exit 1 ; }

	s3_create_bucket $TARGET_BUCKET
	s3_setup_website $TARGET_BUCKET
	deploy_folder "$TARGET_BUCKET" "$FOLDER"
	[[ -z $GZIP_FILES ]] || deploy_gzip $TARGET_BUCKET $GZIP_FILES
	[[ -z $SHORT_EXPIRY ]] || deploy_short_expiry $TARGET_BUCKET $SHORT_EXPIRY
}

main "$@"

