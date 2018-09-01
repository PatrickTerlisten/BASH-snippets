#!/usr/local/bin/bash

# written by    :       Terlisten, Patrick
# last change   :       2017-05-15, Terlisten

# GENERAL SETTINGS
DATE=`date +"%Y%m%d"`
BACKUPDIR=/root/backup
LOGFILE=/var/log/backup.log
LOCK=/var/run/backup.lock

# SCRIPT

function log()
  {
    echo `date +%d.%m.%Y%t%H:%M:%S` "    LOG:" $1 | tee -a ${LOGFILE}
  }

function error()
  {
    echo `date +%d.%m.%Y%t%H:%M:%S` "    ERROR:" $1 | tee -a ${LOGFILE}
    exit 1
  }

if [ -f ${LOCK} ] ; then
  error "Lockfile ${LOCK} exists."
fi

touch ${LOCK}

if [ ! -d ${BACKUPDIR} ] ; then
  log "Creating backup directory"
  mkdir -p ${BACKUPDIR}
fi

log "Creating MariaDB backup"
mysqldump -AaCceQ | gzip > $BACKUPDIR/$DATE-alldatabases.sql.gz
log "Creating /etc backup" 
tar cjfp $BACKUPDIR/$DATE-etc.tar.bz2 /etc
log "Creating /usr/local/etc backup"
tar cjfp $BACKUPDIR/$DATE-usr-local-etc.tar.bz2 /usr/local/etc
log "Creating /usr/local/www backup"
tar cjfp $BACKUPDIR/$DATE-www.tar.bz2 /usr/local/www
log "Removing files older 30 days"
find ${BACKUPDIR} -type file -mindepth 1 -mtime +30 -delete
log "Copy backups to mx02.blazilla.de"
rsync --delete -aue "ssh -p 4712" /root/backup mx02.blazilla.de:/root/backup-mx01

rm ${LOCK}

log "Backup finished!"

exit 0
