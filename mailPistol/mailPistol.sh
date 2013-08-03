#!/bin/bash
P_LINK="http://dev.ashep.org/scribbles/mailPistol"
P_VER="10.6.28"
P_AUTH="Alexander Shepetko <dev@ashep.org>"

CFG="/usr/local/etc/mailPistol.conf"
VERBOSE=0
ZIP=0
while getopts "hvzf:t:c:b:g:" OPTVAR
do
	case ${OPTVAR} in 
		"v") VERBOSE=1 ;;
		"z") ZIP=1 ;;
		"f") _EMAIL_FROM=${OPTARG} ;;
		"t") _EMAIL_TO=${OPTARG} ;;
		"c") _EMAIL_CC=${OPTARG} ;;
		"b") _EMAIL_BCC=${OPTARG} ;;
		"g") CFG=${OPTARG} ;;
		"h") 
			echo "mailPistol-${P_VER} by ${P_AUTH}"
			echo "See details at ${P_LINK}"
			echo ""
			echo "Usage: ${0} [-h] [-v] [-z] [-g config_file] [-f from_email] [-t \"to_email\"] [-c \"cc_email\"] [-b \"bcc_email\"]"
			exit 0
			;;
		"?") exit 1 ;;
	esac
done

if [ ${VERBOSE} -eq 1 ]
then
	echo "mailPistol-${P_VER} by ${P_AUTH}"
	echo "See details at ${P_LINK}"
	echo ""
fi

# Loading config-file
if [ ! -r ${CFG} ]
then
	echo "Unable to load config-file from: ${CFG}" >&2
	exit 1
fi
. ${CFG}

# Setting up variables from command-line arguments
[ -n "${_EMAIL_FROM}" ] && EMAIL_FROM=${_EMAIL_FROM}
[ -n "${_EMAIL_TO}" ] && EMAIL_TO=${_EMAIL_TO}
[ -n "${_EMAIL_CC}" ] && EMAIL_CC=${_EMAIL_CC}
[ -n "${_EMAIL_BCC}" ] && EMAIL_BCC=${_EMAIL_BCC}

# Checking for required variables
if [ -z "${EMAIL_FROM}" ]
then
	echo "Variable EMAIL_FROM not set" >&2
	exit 1
fi
if [ -z "${EMAIL_TO}" ]
then
	echo "Variable EMAIL_TO not set" >&2
	exit 1
fi
if [ -z "${EMAIL_MSG}" ]
then
	echo "Variable EMAIL_MSG not set" >&2
	exit 1
fi
if [ -z "${EMAIL_SUBJ}" ]
then
	echo "Variable EMAIL_SUBJ not set" >&2
	exit 1
fi
if [ -z "${SMTP_HOST}" ]
then
	echo "Variable SMTP_HOST not set" >&2
	exit 1
fi
if [ -z "${SRC_DIR}" ]
then
	echo "Variable SRC_DIR not set" >&2
	exit 1
fi
if [ -z "${SENT_DIR}" ]
then
	echo "Variable SENT_DIR not set" >&2
	exit 1
fi
[ -z "${FNAMES_PATTERN}" ] && FNAMES_PATTERN="*"
if [ ! ${FILES_COUNT} -gt 0 ]
then
	echo "Variable FILES_COUNT not set" >&2
	exit 1
fi

# Searching for sendEmail
SENDEMAIL_BIN=`which sendEmail`
if [ -z ${SENDEMAIL_BIN} ]
then
	echo "sendEmail not found" >&2
	[ ${VERBOSE} -eq 1 ] && echo "Visit http://caspian.dotconf.net/menu/Software/SendEmail/ for details"
	exit 1
fi
[ ${VERBOSE} -eq 1 ] && echo "sendEmail found: ${SENDEMAIL_BIN}"

# Searching for GNU find
FIND_BIN=`which find`
if [ -z ${FIND_BIN} ]
then
	echo "GNU find not found" >&2
	[ ${VERBOSE} -eq 1 ] && echo "Visit http://www.gnu.org/software/findutils/ for details"
	exit 1
fi
[ ${VERBOSE} -eq 1 ] && echo "GNU find found: ${FIND_BIN}"

# Searching for ZIP
if [ ${ZIP} -eq 1 ]
then
	ZIP_BIN=`which zip`
	if [ -z ${ZIP_BIN} ]
	then
		echo "Zip not found" >&2
	[ ${VERBOSE} -eq 1 ] && echo "Visit http://www.info-zip.org/ for details"
		exit 1
	fi
	[ ${VERBOSE} -eq 1 ] && echo "Zip found: ${ZIP_BIN}"
fi

# Checking source directory
if [ ! -d ${SRC_DIR} -o ! -w ${SRC_DIR} ]
then
	echo "Cant't open source directory: ${SRC_DIR}" >&2
	exit 1
fi
[ ${VERBOSE} -eq 1 ] && echo "Source directory successfuly opened: ${SRC_DIR}"

# Checking directory for storing sent files
if [ ! -d ${SENT_DIR} -o ! -w ${SENT_DIR} ]
then
	echo "Cant't open directory for storing sent files: ${SENT_DIR}" >&2
	exit 1
fi
[ ${VERBOSE} -eq 1 ] && echo "Directory for storing sent files successfuly opened: ${SENT_DIR}"

# Scaning input directory
IFS=$'\t'
FILES=($(${FIND_BIN} ${SRC_DIR} -type f -iname ${FNAMES_PATTERN} -printf "%p\t"))
unset IFS
if [ ${#FILES[@]} -eq 0 ]
then
	echo "No file(s) found: '${SRC_DIR}/${FNAMES_PATTERN}'" >&2
	exit 1
fi
[ ${VERBOSE} -eq 1 ] && echo "${#FILES[*]} files found"

# Calculating number of files to send
[ ${FILES_COUNT} -gt ${#FILES[*]} ] && FILES_COUNT=${#FILES[*]}
[ ${VERBOSE} -eq 1 ] && echo "${FILES_COUNT} files will be sent"

# Building array that contains filenames to send
for CNT in `seq 0 $((${FILES_COUNT} - 1))`
do
	FILES_TO_SEND[${CNT}]=${FILES[${CNT}]}
done
ATTACHMENTS=("${FILES_TO_SEND[@]}")

# Verbosing or not in applications
VBS=""
[ ${VERBOSE} -eq 0 ] && VBS="-q"
[ ${VERBOSE} -eq 1 ] && VBS="-v"

# Zipping, if need it
if [ ${ZIP} -eq 1 ]
then
	[ -z "${ZIP_NAME}" ] && ZIP_NAME="files.zip"
	( echo ${ZIP_NAME} | grep -i '\.zip$'; ) || ZIP_NAME="${ZIP_NAME}.zip"
	[ -z "${ZIP_OPTS}" ] && ZIP_OPTS="-j"
	
	${ZIP_BIN} ${ZIP_OPTS} ${VBS} ${ZIP_NAME} "${FILES_TO_SEND[@]}"
	
	if [ ${?} -ne 0 ]
	then
		echo "Unable to create zip archive" >&2
		exit 1
	fi
	ATTACHMENTS=(${ZIP_NAME}) # Archive name
fi

# Sending files
SENDEMAIL_ADD_OPTS=""
[ -n "${INET_ADDR}" ] && SENDEMAIL_ADD_OPTS="${SENDEMAIL_ADD_OPTS} -b ${INET_ADDR}"
[ -n "${SMTP_FQDN}" ] && SENDEMAIL_ADD_OPTS="${SENDEMAIL_ADD_OPTS} -o fqdn=${SMTP_FQDN}"
[ -n "${SMTP_USER}" ] && SENDEMAIL_ADD_OPTS="${SENDEMAIL_ADD_OPTS} -xu ${SMTP_USER}"
[ -n "${SMTP_PASSWD}" ] && SENDEMAIL_ADD_OPTS="${SENDEMAIL_ADD_OPTS} -xp ${SMTP_PASSWD}"

${SENDEMAIL_BIN} ${VBS} -f "${EMAIL_FROM}" -t "${EMAIL_TO}" \
	-cc "${EMAIL_CC}" -bcc "${EMAIL_BCC}" \
	-u "${EMAIL_SUBJ}" -m "${EMAIL_MSG}" -a "${ATTACHMENTS[@]}" \
	-s ${SMTP_HOST} ${SENDEMAIL_ADD_OPTS}

if [ ${?} -ne 0 ]
then
	echo "Unable to send files" >&2
	exit 1
fi

# Moving files to sent-dir
mv -f "${FILES_TO_SEND[@]}" ${SENT_DIR}
if [ ${?} -ne 0 ]
then
	echo "Unable to move "${FILES_TO_SEND[@]}" to ${SENT_DIR}" >&2
	exit 1
fi

# Removing zip archive
if [ ${ZIP} -eq 1 ]
then
	rm -f "${ATTACHMENTS[@]}"
	if [ ${?} -ne 0 ]
	then
		echo "Unable to remove ${ATTACHMENTS[@]}" >&2
		exit 1
	fi
fi

