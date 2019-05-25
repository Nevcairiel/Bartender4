#!/bin/bash

tempfile=$( mktemp )

cleanup() {
  rm -f $tempfile
  rm -f exported-locale-strings.lua
}
trap cleanup EXIT

do_import() {
  namespace="$1"
  file="$2"
  : > "$tempfile"

  echo -n "Importing $namespace..."
  result=$( curl -sS -X POST -w "%{http_code}" -o "$tempfile" \
    -H "X-Api-Token: $CF_API_TOKEN" \
    -F "metadata={ language: \"enUS\", namespace: \"$namespace\", \"missing-phrase-handling\": \"DeletePhrase\" }" \
    -F "localizations=<$file" \
    "https://www.wowace.com/api/projects/13501/localization/import"
  ) || exit 1
  case $result in
    200) echo "done." ;;
    *)
      echo "error! ($result)"
      [ -s "$tempfile" ] && grep -q "errorMessage" "$tempfile" && cat "$tempfile" | jq --raw-output '.errorMessage'
      exit 1
      ;;
  esac
}

lua locale/find-locale-strings.lua || exit 1
tra

do_import "" "exported-locale-strings.lua"

exit 0
