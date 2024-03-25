#!/usr/bin/env bash

VM_DIST_LIST_DEFAULT="
RHEL|8
RHEL|9
Windows/server|2016
Windows/server|2019
Windows/server|2022
Windows/desktop|10
Windows/desktop|11
"

#VM_DIST_LIST_DEFAULT="
#CentOS|8
#"

VM_DIST_LIST=${1:-${VM_DIST_LIST_DEFAULT}}
PROJECT_DIR=$( git rev-parse --show-toplevel )
TEMPLATE_DIR="${PROJECT_DIR}/templates"

HCL2_FORMAT="hcl"

## ref: https://stackoverflow.com/questions/10982911/creating-temporary-files-in-bash
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
TIMESTAMP=$(date +%Y%m%d%H%M%S)
#BACKUP_HCL_FILES=1
BACKUP_HCL_FILES=0

SED_CMD=sed
# Mac OSX's GNU sed is installed as gsed
# use e.g. homebrew 'gnu-sed' to get it
if ! sed --version >/dev/null 2>&1; then
  if gsed --version >/dev/null 2>&1; then
    SED_CMD=gsed
  else
    echo "Error, can't find an acceptable GNU sed." >&2
    exit 1
  fi
fi

cd "${TEMPLATE_DIR}"

## ref: https://unix.stackexchange.com/questions/573047/how-to-get-the-relative-path-between-two-directories
pnrelpath() {
  ## get the relative path between two directories
  set -- "${1%/}/" "${2%/}/" ''               ## '/'-end to avoid mismatch
  while [ "$1" ] && [ "$2" = "${2#"$1"}" ]    ## reduce $1 to shared path
  do  set -- "${1%/?*/}/"  "$2" "../$3"       ## source/.. target ../relpath
  done
  REPLY="${3}${2#"$1"}"                       ## build result
  # unless root chomp trailing '/', replace '' with '.'
  [ "${REPLY#/}" ] && REPLY="${REPLY%/}" || REPLY="${REPLY:-.}"
  echo "${REPLY}"
}

function convert_json2hcl() {

  JSON_FILE=$1
  FILE_TYPE=${2:-"vars"}
  BUILD_DIST=${3:-$(dirname "${JSON_FILE}")}

  JSON_SOURCE_FILE="${JSON_FILE}"

  echo "==> BUILD_DIST=${BUILD_DIST}"

  if [[ ${BACKUP_HCL_FILES} -ne 0 ]]; then
    if [ -e "${HCL2_FILE}" ]; then
      echo "==> backup existing ${HCL2_FILE}"
      mv "${HCL2_FILE}" "${HCL2_FILE}.${TIMESTAMP}~"
    fi
  fi

  HCL2_FILE_FORMAT="pkr.${HCL2_FORMAT}"
#  if [[ "${FILE_TYPE}" == "vardef" ]]; then
#    HCL2_FILE_FORMAT="pkr.hcl"
#    ## ref: https://stackoverflow.com/questions/48470049/build-a-json-string-with-bash-variables
#    #echo "==> create empty variables json"
#    #VARS_JSON=$(jq -n '{variables: {} }')
#    #echo "==> VARS_JSON=${VARS_JSON}"
#
#    JSON_SOURCE_FILE="${TEMP_DIR}/$(basename ${JSON_FILE})"
#
#    ## ref: https://unix.stackexchange.com/questions/460985/jq-add-objects-from-file-into-json-array
#    ## ref: https://stackoverflow.com/questions/38860529/create-json-using-jq-from-pipe-separated-keys-and-values-in-bash
#    if [[ "${FILE_TYPE}" == "vardef" ]]; then
#      echo "==> Create variable definition vars json file at [${JSON_SOURCE_FILE}]"
#      jq --argjson varInfo "$(<${JSON_FILE})" '.variables += $varInfo' -n '{variables: $varInfo }' > "${JSON_SOURCE_FILE}"
#    fi
#  elif [[ "${FILE_TYPE}" == "vars" ]]; then
  if [[ "${FILE_TYPE}" == "vars" ]]; then
    ### ref: https://www.virtualizationhowto.com/2022/06/convert-packer-variables-json-to-hcl2-for-automated-vsphere-builds/
    ##HCL2_FILE_FORMAT="pkrvars.hcl"
    ### ref: https://developer.hashicorp.com/packer/guides/hcl/variables
    ## HCL2_FILE_FORMAT="vars.hcl"
    HCL2_FILE_FORMAT="pkrvars.${HCL2_FORMAT}"
  fi

  HCL2_FILE="${JSON_FILE}.${HCL2_FILE_FORMAT}"

  echo "*******"
  if [[ "${FILE_TYPE}" == "vars" ]]; then
    echo "==> Create variable block vars json file at [${JSON_SOURCE_FILE}]"
    ## ref: https://stackoverflow.com/questions/66564551/convert-json-to-simple-key-value-file-using-jq
    ## ref: https://stackoverflow.com/questions/25378013/how-to-convert-a-json-object-to-key-value-format-in-jq
    ## preserve escape character '\'
    jq -r 'to_entries[] | (.key) + "=\"" + .value +"\""' < "${JSON_FILE}" | sed 's/\\/\\\\/' > "${HCL2_FILE}"
  else
    echo "==> Convert [${JSON_SOURCE_FILE}] to [${HCL2_FILE}]"
    PACKER_CONVERT_CMD="packer hcl2_upgrade -output-file=${HCL2_FILE} -with-annotations ${JSON_SOURCE_FILE}"
    echo "==> Running [${PACKER_CONVERT_CMD}]"
    eval "${PACKER_CONVERT_CMD}"
  fi

  if [[ "${FILE_TYPE}" == "build" ]]; then
    BUILD_PLATFORM=$(echo "${BUILD_DIST}" | cut -d/ -f1)
    echo "==> Convert autogenerated_* pattern to platform [${BUILD_PLATFORM}]"
    "${SED_CMD}" -i 's|autogenerated_\([0-9]\+\)|'"${BUILD_PLATFORM}"'|g' "${HCL2_FILE}"
  fi

#    echo "==> Convert templatefile pattern"
##    "${SED_CMD}" -i 's|"{{ templatefile($\(.*\),\(.*\)) }}"|templatefile\("\1",\2\)|g' "${HCL2_FILE}"
#    "${SED_CMD}" -i 's|"templatefile(\(.*\), $\(.*\))"|templatefile\("\1", "\2"\)|g' "${HCL2_FILE}"

  echo "==> Convert \$$ to $ in ${HCL2_FILE}"
  "${SED_CMD}" -i 's|\$\$|\$|g' "${HCL2_FILE}"

  echo "==> Convert \\\" to \" in ${HCL2_FILE}"
  "${SED_CMD}" -i 's|\\\"|\"|g' "${HCL2_FILE}"

  echo "==> Convert template function patterns (prefixed with %%) in ${HCL2_FILE}"
##    "${SED_CMD}" -i 's|"%%\(.*\)(\(.*\), $\(.*\))"|\1\("\2", "\3"\)|g' "${HCL2_FILE}"
#    "${SED_CMD}" -i 's|"%%\(.*\)(\(.*\), \(.*\))"|\1\("\2", "\3"\)|g' "${HCL2_FILE}"

#  "${SED_CMD}" -i 's|"%%\(.*\)(\(.*\))"|\1\(\2\)|g' "${HCL2_FILE}"
  "${SED_CMD}" -i 's|"%%\(.*\)"|\1|g' "${HCL2_FILE}"

}

function convert_dist2hcl() {
  VM_DIST_INFO=$1

  # ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
  # split server name from sub-list
  IFS="|" read -a DIST_INFO_ARRAY <<< $VM_DIST_INFO
  VM_DIST=${DIST_INFO_ARRAY[0]}
  VM_DIST_VERSION=${DIST_INFO_ARRAY[1]}

  echo "==> DIST_INFO_ARRAY LENGTH=${#DIST_INFO_ARRAY[@]}"

#  if [ ${#DIST_INFO_ARRAY[@]} -gt 2 ]; then
#    VM_DIST_VERSION+="/${DIST_INFO_ARRAY[2]}"
#  fi
  VM_DIST_DIR="${VM_DIST}"
  VM_DIST_VERSION_DIR="${VM_DIST_DIR}/${VM_DIST_VERSION}"

  echo "==> VM_DIST=[$VM_DIST]"
  echo "==> VM_DIST_VERSION=[$VM_DIST_VERSION]"

#  COMMON_VARS_FILE_HCL="${COMMON_VARS_FILE_JSON}.pkr.hcl"
#  if [[ ! -e "${VM_DIST_DIR}/${COMMON_VARS_FILE_HCL}" ]]; then
#    echo "==> Create symbolic link to ${COMMON_VARS_FILE_HCL}"
#    cd "${VM_DIST_DIR}"
#    ln -sf "../${COMMON_VARS_FILE_HCL}" .
#    cd ../
#  fi

  TEMPLATE_BASE_DIRECTORY=$PWD

  echo "==> BASE_DIRECTORY=$TEMPLATE_BASE_DIRECTORY"

#  COMMON_VARS_FILE_HCL_LIST=$(find "${TEMPLATE_DIR}/" -maxdepth 1 -type f -wholename "*.pkr.hcl" | sort)
  COMMON_VARS_FILE_HCL_LIST=$(find "${TEMPLATE_DIR}/" -maxdepth 1 -type f -wholename "*.hcl" | sort)
  echo "==> COMMON_VARS_FILE_HCL_LIST=[$COMMON_VARS_FILE_HCL_LIST]"

  echo "==> Link common var HCL files into each VM_DIST_DIR"
  IFS=$'\n'
  for COMMON_VAR_HCL_FILE in ${COMMON_VARS_FILE_HCL_LIST}
  do
    echo "**************************************"
    echo "==> Link hcl2 var file [${COMMON_VAR_HCL_FILE}] to VM_DIST_DIR [$VM_DIST_DIR]"
    echo pwd=`pwd`
    cd "${VM_DIST_DIR}"
    RELPATH=$(pnrelpath "$PWD" "$TEMPLATE_BASE_DIRECTORY")
    echo "RELPATH=${RELPATH}"

    ln -sf "${RELPATH}/$(basename ${COMMON_VAR_HCL_FILE})" .
#    ln -sf "../$(basename ${COMMON_VAR_HCL_FILE})" .
#    cd ../
    cd "${TEMPLATE_BASE_DIRECTORY}"
  done

  DIST_VAR_FILE_LIST=$(\
    (find "${VM_DIST_DIR}/" -type f -wholename "*/distribution-vars.json" &&
    find "${VM_DIST_VERSION_DIR}/" -type f -wholename "*/box_info.*json" &&
    find "${VM_DIST_VERSION_DIR}/" -type f -wholename "*/template.json") \
    | sort)

#  DIST_VARS_FILE_JSON="${VM_DIST_DIR}/distribution-vars.json"
#  DIST_BOX_VARS_FILE_JSON="${VM_DIST_VERSION_DIR}/box_info.json"
#  DIST_TEMPLATE_VARS_FILE_JSON="${VM_DIST_VERSION_DIR}/template.json"
  DIST_BUILD_FILE_JSON="${VM_DIST_DIR}/build-config.json"

  echo "==> Convert each dist var file"
  IFS=$'\n'
  for DIST_VAR_FILE in ${DIST_VAR_FILE_LIST}
  do
    if [ -e "${DIST_VAR_FILE}" ]; then
      echo "==> Convert ${DIST_VAR_FILE}"
      convert_json2hcl "${DIST_VAR_FILE}"
    fi
  done

  echo "==> Convert ${DIST_BUILD_FILE_JSON}"
  convert_json2hcl "${DIST_BUILD_FILE_JSON}" "build"
}

function main() {
  COMMON_VARS_FILE="common-vars"
  COMMON_VARS_FILE_JSON="${COMMON_VARS_FILE}.json"

  echo "==> Convert ${COMMON_VARS_FILE_JSON}"
  convert_json2hcl "${COMMON_VARS_FILE_JSON}" "vardef"

  ENV_VAR_FILE_LIST=$(find . -maxdepth 1 -type f -name "env-vars.*.json" | sort)
  echo "==> ENV_VAR_FILE_LIST=[$ENV_VAR_FILE_LIST]"

  echo "==> Convert env var files"
  IFS=$'\n'
  for ENV_VAR_FILE in ${ENV_VAR_FILE_LIST}
  do
    echo "**************************************"
    echo "==> Convert env var json to hcl2 for VM_DIST_INFO [$VM_DIST_INFO]"
    echo "==> Convert ${ENV_VAR_FILE}"
    convert_json2hcl "${ENV_VAR_FILE}"
  done

  IFS=$'\n'
  for VM_DIST_INFO in ${VM_DIST_LIST}
  do

    echo "**************************************"
    echo "**************************************"
    echo "==> Convert dist var json to hcl2 for VM_DIST_INFO [$VM_DIST_INFO]"
    convert_dist2hcl "${VM_DIST_INFO}"
    echo "**************************************"

  done

}

main "$@"