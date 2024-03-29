#!/usr/bin/env sh
#########################################################
#   Script Requirements
#
#   Files:
#      vars_to_skip
#      vars_preferred
#
#   Programs:
#      curl
#########################################################

#########################################################
# setup variables
#
# DATE         - Date
# MAC         - Mac address
# FILE         - File Name Prefix
# CUR_DIR      - Current Directory
# transfer      - FTP Transfer ON/OFF (Default is OFF)
# FOLDER      - Location where backup scripts are stored
# VARFILE      - Location & Name of Temp File
# TO_ALL      - Location & Name of script File with all nvram variables
# TO_INCLUDE   - Location & Name of script File with essential nvram variables
# TO_EXCLUDE   - Location & Name of script File with dangerous nvram variables
# TO_PREFERRED   - Location & Name of script File with preferred nvram variables
#
#########################################################

DATE=`date +%m%d%Y`
MAC=`nvram get lan_hwaddr | tr -d ":"`
FILE=${MAC}.${DATE}
CUR_DIR=`dirname $0`
transfer=0
FOLDER=/tmp/vars/backups
VARFILE=/tmp/all_vars
TO_ALL=${FOLDER}/${MAC}.${DATE}.all.sh
TO_INCLUDE=${FOLDER}/${MAC}.${DATE}.essential.sh
TO_EXCLUDE=${FOLDER}/${MAC}.${DATE}.dangerous.sh
TO_PREFERRED=${FOLDER}/${MAC}.${DATE}.preferred.sh

#########################################################
#FTP Login information change to your info
#########################################################

FTPS=ftp://192.168.1.100/backups
USERPASS=user:pass

#########################################################
# read command line switches
#
#   example command lines
#
#   ./backupvars.sh -t
#
#   The above command with use the user and password and
#   server information embedded in this script.
#   (See FTP Login information above)
#
#
#   ./backupvars.sh -t -u user:pass -f ftp://192.168.1.100/backups
#
#   The above command with use the user and password and
#   server information from the command line
#
#########################################################

while getopts tu:f: name
do
  case $name in
  t)   transfer=1;;
  u)   USERPASS="$OPTARG";;
  f)   FTPS="$OPTARG";;
  ?)   printf "Usage: %s: [-t] [-u username:password] [-f ftpserver]\n"
       exit 2;;
  esac
done
shift $(($OPTIND - 1))

#########################################################
#create NVRAM variale list and write to /opt/tmp/all_vars
#########################################################

nvram show 2>/dev/null | grep -E '^[A-Za-z][A-Za-z0-9_\.\-]*=' | awk -F = '{print $1}' | sort -r -u >${VARFILE}

#########################################################
# Write header to restore scripts
#########################################################

mkdir -p $FOLDER
echo -e "#!/bin/sh\n#\necho \"Write variables\"\n" | tee -i ${TO_EXCLUDE} | tee -i ${TO_PREFERRED} | tee -i  ${TO_ALL} > ${TO_INCLUDE}

#########################################################
# scan NVRAM variable list and send variable to proper
# restore script
#########################################################

cat ${VARFILE} | while read var
do
  pref=0
 ### replaced with next line by Andon Mančev :  if echo "${var}" | grep -q -f "${CUR_DIR}/vars_to_skip" ; then
if echo ${var} | grep -q -f "${CUR_DIR}/vars_to_skip" ; then
    bfile=$TO_EXCLUDE
  else
    bfile=$TO_INCLUDE
    pref=`echo "${var}" | grep -cf "${CUR_DIR}/vars_preferred"`
  fi

  # get the data out of the variable
  data=`nvram get ${var}`
  # write the var to the file and use \ for special chars: (\$`")
  echo -en "nvram set ${var}=\"" | tee -ia ${TO_ALL} >> ${bfile}
  echo -n "${data}" |  sed -e 's/[$`"\]/\\&/g' | tee -ia  ${TO_ALL} >> ${bfile}
  echo -e "\"" | tee -ia  ${TO_ALL} >> ${bfile}
  if [ ! ${pref} == 0 ]; then
    echo -en "nvram set ${var}=\"" >> ${TO_PREFERRED}
    echo -n "${data}" |  sed -e 's/[$`"\]/\\&/g' >> ${TO_PREFERRED}
    echo -e "\"" >> ${TO_PREFERRED}
  fi
done

#########################################################
# cleanup remove /opt/tmp/all_vars
# uncomment to remove file
#########################################################

# rm ${VARFILE}

#########################################################
# Write footer to restore script
#########################################################

echo -e "\n# Commit variables\necho \"Save variables to nvram\"\nnvram commit"  | tee -ia  ${TO_ALL} | tee -ia  ${TO_PREFERRED} | tee -ia  ${TO_EXCLUDE} >> ${TO_INCLUDE}

#########################################################
# Change permissions on restore scripts to make them
# executable
#########################################################

chmod +x ${TO_INCLUDE}
chmod +x ${TO_PREFERRED}
chmod +x ${TO_EXCLUDE}
chmod +x ${TO_ALL}

#########################################################
# Compress restore scripts and send them to ftp server
#########################################################

if [ ${transfer} -ne 0 ] ; then
  tar cpf - -C / "${TO_INCLUDE}" 2>/dev/null | gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.essential.sh.tgz" -T -
  tar cpf - -C / "${TO_PREFERRED}" 2>/dev/null | gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.preferred.sh.tgz" -T -
  tar cpf - -C / "${TO_EXCLUDE}" 2>/dev/null | gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.dangerous.sh.tgz" -T -
  tar cpf - -C / "${TO_ALL}" 2>/dev/null | gzip -c |  /opt/bin/curl -s -u ${USERPASS} "${FTPS}/${FILE}.all.sh.tgz" -T -
fi
