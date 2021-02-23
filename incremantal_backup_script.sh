#!/bin/sh

RSYNC="/usr/bin/sudo /usr/bin/rsync"
TODAY=`date +"%Y%m%d"`
YESTERDAY=`date -d "1 day ago" +"%Y%m%d"`
OLDBACKUP=`date -d "30 days ago" +"%Y%m%d"`

IPLIST="/backup/ip.txt"

for i in $(cat $IPLIST)
do
HOSTNAME=`ssh root@$i hostname`
FILE={'/backup','/home'}
SOURCE="root@$i"
FILE1={'/etc/mysql/my.cnf','/etc/nginx'}

SHAREUSR="/backup/$HOSTNAME/database"
SHAREUSR1="/backup/$HOSTNAME/files"
SHAREUSR2="/backup/$HOSTNAME/config"


#log_files
LOG="/backup/BACKUPLOG/${HOSTNAME}_backup.log"

LATEST_LINK="${SHAREUSR}/latest"
LATEST_LINK1="${SHAREUSR1}/latest"
LATEST_LINK2="${SHAREUSR2}/latest"

mkdir -p $SHAREUSR
mkdir -p $SHAREUSR1
mkdir -p $SHAREUSR2

mkdir -p $SHAREUSR/$TODAY
mkdir -p $SHAREUSR1/$TODAY
mkdir -p $SHAREUSR2/$TODAY

BACKUP_PATH="$SHAREUSR/$TODAY"
BACKUP_PATH1="$SHAREUSR1/$TODAY"
BACKUP_PATH2="$SHAREUSR2/$TODAY"



for DATABASE in `ssh -p22 $SOURCE "mysql -u root -e 'show databases'"  | awk {'print $1'} |grep -v Database | grep -v _schema`;
do
ssh -p22 $SOURCE "mysqldump \
 --user=root \
 $DATABASE \
 | gzip -9" > $SHAREUSR/$TODAY/$DATABASE.sql.gz
done




rsync -avzh -e 'ssh -p22' \
 --rsync-path="$RSYNC" \
 --exclude="cache" \
 --exclude="log" \
 --link-dest=../$YESTERDAY $SOURCE:$FILE $BACKUP_PATH1



rsync -avzh -e 'ssh -p22' \
 --rsync-path="$RSYNC" \
 --exclude="cache" \
 --exclude="log" \
 --link-dest=../$YESTERDAY $SOURCE:$FILE1 $BACKUP_PATH2


echo -e "\ndatabase $DATABASE $HOSTNAME backed up $TODAY " >> $LOG


rm -R $SHAREUSR/$OLDBACKUP
rm -R $SHAREUSR1/$OLDBACKUP
rm -R $SHAREUSR2/$OLDBACKUP

rm -rf "${LATEST_LINK}"
ln -s "${BACKUP_PATH}" "${LATEST_LINK}"

rm -rf "${LATEST_LINK1}"
ln -s "${BACKUP_PATH1}" "${LATEST_LINK1}"

rm -rf "${LATEST_LINK2}"
ln -s "${BACKUP_PATH2}" "${LATEST_LINK2}"
done

