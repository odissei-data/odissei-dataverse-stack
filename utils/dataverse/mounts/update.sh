#!/bin/bash

# This script addapts the given dataset.xhtml file 
# in order to remove (comment out) the Files tab and the Versions tab 
# And then copies that adapted file to the dataverse container

# check if we have the right number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <dataverse_container_name>"
    exit 1
fi
DATAVERSE_CONTAINER=$1


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_DIR="$(pwd)"

cd "$SCRIPT_DIR" || exit 1

# The initial (original) file is copied from the dataverse container, it is the correct version by definition
docker cp "$DATAVERSE_CONTAINER":/opt/payara/deployments/dataverse/dataset.xhtml ./dataset.xhtml

COMMENT_TAG="ODISSEI commented out this block"

# check if file already contains the comment 
if grep -q "<!-- $COMMENT_TAG" dataset.xhtml; then
  echo "dataset.xhtml file already contains the comment: '$COMMENT_TAG', skipping adaptation."
  echo "Please remove the comments (uncomment) manually if you want to adapt the file again."
  exit 0
fi

echo "Starting to adapt dataset.xhtml file..."

awk -v comment_tag="$COMMENT_TAG" '
BEGIN {
  # List of tag patterns to comment out (case-sensitive)
  tags["p:tab id=\"versionsTab\""]
  tags["p:tab id=\"dataFilesTab\""]
  tags["p:commandButton id=\"fileTagsPopupSaveButton\""]
  inblock = 0
}

{
  # Start block: check if line contains one of the start tags
  for (tag in tags) {
    if ($0 ~ "<" tag) {
    comment_start="<!-- " comment_tag
    print comment_start
      inblock = 1
      break
    }
  }

  # Inside a block, print the line
  if (inblock) {
    print

    # End block: look for closing tag
    for (tag in tags) {
      split(tag, tparts, " ")
      endtag = "</" tparts[1] ">"
      if ($0 ~ endtag) {
        print "-->"
        inblock = 0
        break
      }
    }
    next
  }

  # Outside a block, print normally
  print
}
' dataset.xhtml > dataset_commented.xhtml
# Remove specific strings from the adapted file
# List the strings to remove, separated by |
STRINGS_TO_REMOVE=",:datasetForm:tabView:filesTable|:datasetForm:tabView:filesTable,"

if [ -n "$STRINGS_TO_REMOVE" ]; then
  sed -i -E "s/($STRINGS_TO_REMOVE)//g" dataset_commented.xhtml
fi

echo "Finished adapting dataset.xhtml file, now copying to dataverse container..."

# Copy the adapted file to the dataverse container
docker cp dataset_commented.xhtml "$DATAVERSE_CONTAINER:/opt/payara/deployments/dataverse/dataset.xhtml"
# Remove the temporary file
#rm dataset_commented.xhtml

cd "$CURRENT_DIR" || exit 1
