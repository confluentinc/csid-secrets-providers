#!/usr/bin/env bash

fileBasedScanStatus="${SENSITIVE_INFO_SCAN_FROM_FILE:-true}"
customRegex="$SENSITIVE_INFO_CUSTOM_REGEX"
IFS="$SENSITIVE_INFO_CUSTOM_DELIMITER"

cacheKeyName="$SEMAPHORE_WORKFLOW_ID-SCAN-RESULT"
cacheFileName="/tmp/$SEMAPHORE_WORKFLOW_ID-SCAN-RESULT.txt"
commonRegexFileName="$SEMAPHORE_GIT_DIR/mk-include/resources/sensitiveInfoRegex.txt"
testResultFile="$SEMAPHORE_GIT_DIR/build/*TEST-result.xml"
parsedResultFile="$SEMAPHORE_GIT_DIR/build/parsed-result-file.xml"


# Declare leakOutput array
leakOutput=()

parseResultFile() {
 # Remove the pattern (\") from test result file and store it in a new file. (\") this pattern gets attached to the logs when running with verbose flag enabled.
 sed -e 's/\\"//g' $testResultFile > "$parsedResultFile"
}

matchPatternAndStore() {
  if [[ -n $1 ]]; then
    output=$(egrep -i "$1" $parsedResultFile)
    if [[ -n $output ]]; then
      leakOutput+=("$output")
    fi
  fi
}

parseLogsUsingCommonRegexFile() {
  # Iterate over regexes present in common file
  while read -r secretMatchPattern; do
    matchPatternAndStore "$secretMatchPattern"
  done < "$1"
}

parseLogsUsingCustomRegexString() {
  # Split the word using Internal Field Seperator (IFS)
	
  read -ra array <<<"$1"

  # Loop through the array of regexes

  for secretMatchPattern in "${array[@]}"; do
    matchPatternAndStore "$secretMatchPattern"
  done
}

saveLeakOutput() {
  leakText=$'#### POSSIBLE SENSITIVE INFO LEAK FOUND ## Please check the following logs: \n'
  for leak in "${leakOutput[@]}"; do
    leakText+="$leak"
  done
  leakText+=$'\n ##############################'
  echo "$leakText" >> "$cacheFileName"
}

parseResultFile 

echo "Sensitive Info SCAN from file is set to $fileBasedScanStatus"

if [[ $fileBasedScanStatus == "true" ]]; then

  # Check if environment variable for common regex file(SENSITIVE_INFO_COMMON_REGEX_FILE) is set
  if [[ -z "$commonRegexFileName" ]]; then
    echo "Error: SENSITIVE_INFO_COMMON_REGEX_FILE environment variable is not set"
    exit 1
  fi

  # Loop through all the lines of $SENSITIVE_INFO_COMMON_REGEX_FILE file and match the regex present in each file 
  # against the log file

  echo "Starting Sensitive Info leak check from $commonRegexFileName using env variable SENSITIVE_INFO_COMMON_REGEX_FILE :"

  parseLogsUsingCommonRegexFile "$commonRegexFileName"

  echo "Sensitive Info Leak check completed from file $commonRegexFileName"
else
  echo "***** IGNORING SENSITIVE INFO CHECK FROM FILE *****"
fi

if [[ -z "$customRegex" ]]; then
  echo "Ignoring Sensitive Info Custom Regex check !! To enable custom regex add regex in SENSITIVE_INFO_CUSTOM_REGEX environment variable"
else
  echo "Starting Custom Sensitive Info leak check for $customRegex using Delimiter $IFS"

  parseLogsUsingCustomRegexString "$customRegex"
fi

if [[ ${#leakOutput[@]} -gt 0 ]]; then   # check if out has some lines then print it on console and exit it with status 1
  touch $cacheFileName
  saveLeakOutput
  cache store $cacheKeyName $cacheFileName
  cat $cacheFileName
else
  echo "Sensitive Info Leak check Passed !!"
fi
