#!/bin/bash

# Wrapper for rdiff-backup
# 
# @author Alexander Shepetko <a.shepetko.com>
# @version 12.729

SRC_DIRS=(\
	'/etc' \
	'/home' \
	'/usr/local' \
	'/var/log' \
)
BACKUP_DIR='/home/backup'

# Backup
for DIR in ${SRC_DIRS[*]}; do
	mkdir -p ${BACKUP_DIR}${DIR}
	if [ $? -ne 0 ]; then echo "Unable to create dir '${BACKUP_DIR}${DIR}'"; exit 1; fi
	echo "Backup ${DIR} to ${BACKUP_DIR}${DIR}"
	rdiff-backup --print-statistics ${DIR} ${BACKUP_DIR}${DIR}
	rdiff-backup --force --remove-older-than 1M ${BACKUP_DIR}${DIR}
	echo ""
done
