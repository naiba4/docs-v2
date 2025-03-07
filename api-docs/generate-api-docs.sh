#!/bin/bash

set -e

function buildHugoTemplate {
  version=$1
  apiVersion=$2
  outFilename=$3

  V_LEN_INIT=$(wc -c $version$outFilename.tmp | awk '{print $1}')
  cat "redoc-static${outFilename}.html" >> $version$outFilename.tmp
  V_LEN=$(wc -c $version$outFilename.tmp | awk '{print $1}')

  if ! [[ $V_LEN -gt $V_LEN_INIT  ]]
  then
    echo "Error: bundle was not appended to $version$outFilename.tmp"
    exit $?
  fi

  rm -f "redoc-static${outFilename}.html"
  mkdir -p ../content/influxdb/$version/api
  mv $version$outFilename.tmp ../content/influxdb/$version/api/$outFilename.html
}

function generateHtml {
  filePath=$1
  outFilename=$2
  titleVersion=$3
  titleSubmodule=$4
 
  echo "Bundling $filePath"

  npx --version

  # Use npx to install and run the specified version of redoc-cli.
  # npm_config_yes=true npx overrides the prompt
  # and (vs. npx --yes) is compatible with npm@6 and npm@7.
  npm_config_yes=true npx redoc-cli@0.12.3 bundle $filePath \
    -t template.hbs \
    --title="InfluxDB $titleVersion$titleSubmodule API documentation" \
    --options.sortPropsAlphabetically \
    --options.menuToggle \
    --options.hideDownloadButton \
    --options.hideHostname \
    --options.noAutoAuth \
    --templateOptions.version="$version" \
    --templateOptions.titleVersion="$titleVersion" \
    --templateOptions.titleSubmodule="$titleSubmodule" \
    --output="redoc-static$outFilename.html"
}

function showHelp {
  echo "Usage: generate.sh <options>"
  echo "Commands:"
  echo "-c) Regenerate changed files. To save time in development, only regenerates files that differ from the master branch."
  echo "-h) Show this help message."
}

# Get arguments

generate_changed=1

while getopts "hc" opt; do
  case ${opt} in
    h)
      showHelp
      exit 0
      ;;
    c)
      generate_changed=0
      ;;
    \?)
      echo "Invalid option: $OPTARG" 1>&2
      showHelp
      exit 22
      ;;
    :)
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      showHelp
      exit 22
      ;;
    esac
done

# Get list of versions from directory names
versions="$(ls -d -- */ | grep -v 'node_modules' | grep -v 'openapi')"

for version in $versions
do
  # Trim the trailing slash off the directory name
  version="${version%/}"

  # Define the menu key
  if [[ $version == "cloud-serverless" ]] || [[ $version == "cloud-dedicated" ]] || [[ $version == "clustered" ]]; then
    menu="influxdb_$(echo $version | sed 's/\./_/g;s/-/_/g;')"
  else 
    menu="influxdb_$(echo $version | sed 's/\./_/g;')_ref"
  fi

  # Define the title text based on the version
  if [[ $version == "cloud" ]]; then
    titleVersion="Cloud"
  elif [[ $version == "cloud-serverless" ]]; then
    titleVersion="Cloud Serverless"
  elif [[ $version == "cloud-dedicated" ]]; then
    titleVersion="Cloud Dedicated"
  elif [[ $version == "clustered" ]]; then
    titleVersion="Clustered"
  else
    titleVersion="$version"
  fi

  # Define frontmatter version
  if [[ $version == "cloud-serverless" ]] || [[ $version == "cloud-dedicated" ]] || [[ $version == "clustered" ]]; then
    frontmatterVersion="v3"
  else 
    frontmatterVersion="v2"
  fi

  # Generate the frontmatter
  v2frontmatter="---
title: InfluxDB $titleVersion API documentation
description: >
  The InfluxDB API provides a programmatic interface for interactions with InfluxDB $titleVersion.
layout: api
menu:
  $menu:
    parent: InfluxDB v2 API
    name: v2 API docs
weight: 102
---
"
  v1compatfrontmatter="---
title: InfluxDB $titleVersion v1 compatibility API documentation
description: >
  The InfluxDB v1 compatibility API provides a programmatic interface for interactions with InfluxDB $titleVersion using InfluxDB v1 compatibility endpoints.
layout: api
menu:
  $menu:
    parent: v1 compatibility
    name: View v1 compatibility API docs
weight: 304
---
"
  v3frontmatter="---
title: InfluxDB $titleVersion API documentation
description: >
  The InfluxDB API provides a programmatic interface for interactions with InfluxDB $titleVersion.
layout: api
weight: 102
---
"

  # If the v2 spec file differs from master, regenerate the HTML.
  filePath="${version}/ref.yml"
  update=0
  if [[ $generate_changed == 0 ]]; then
    fileChanged=$(git diff --name-status master -- ${filePath})
    if [[ -z "$fileChanged" ]]; then
    update=1
    fi
  fi

  if [[ $update -eq 0 ]]; then
    outFilename="_index"
    titleSubmodule=""
    generateHtml $filePath $outFilename $titleVersion $titleSubmodule

    # Create temp file with frontmatter and Redoc html
    if [[ $frontmatterVersion == "v3" ]]; then
      echo "$v3frontmatter" >> $version$outFilename.tmp
    else
      echo "$v2frontmatter" >> $version$outFilename.tmp
    fi
    buildHugoTemplate $version v2 $outFilename
  fi

  # If the v1 compatibility spec file differs from master, regenerate the HTML.
  filePath="${version}/swaggerV1Compat.yml"
  update=0

  if [ -e "$filePath" ]; then
    if [[ $generate_changed == 0 ]]; then
      fileChanged=$(git diff --name-status master -- ${filePath})
      if [[ -z "$fileChanged" ]]; then
      update=1
      fi
    fi

    if [[ $update -eq 0 ]]; then
      outFilename="v1-compatibility"
      titleSubmodule="v1 compatibility"
      generateHtml $filePath $outFilename $titleVersion $titleSubmodule

      # Create temp file with frontmatter and Redoc html
      echo "$v1compatfrontmatter" >> $version$outFilename.tmp
      buildHugoTemplate $version v1 $outFilename
    fi
  fi
done
