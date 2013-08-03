#!/bin/bash

# Wrapper for mysqldump
# 
# @author Alexander Shepetko <a.shepetko.com>
# @version 13.0322


BACKUP_DIR=/home/ashep/Seafile/backups/dbs
MYSQL_USER="root"
MYSQL_PASS=""

[ ! -z ${MYSQL_PASS} ] && MYSQL_PASS="-p${MYSQL_PASS}"

for DB_NAME in `echo "SHOW DATABASES" | mysql -N -u ${MYSQL_USER} ${MYSQL_PASS}`; do
	[ ${DB_NAME} == "information_schema" ] && continue
	[ ${DB_NAME} == "performance_schema" ] && continue
	[ ${DB_NAME} == "mysql" ] && continue
	echo "mysqldumping ${DB_NAME}"
	mysqldump -u ${MYSQL_USER} ${MYSQL_PASS} ${DB_NAME} > ${BACKUP_DIR}/${DB_NAME}.sql
	gzip -fv ${BACKUP_DIR}/${DB_NAME}.sql
	echo ""
done
