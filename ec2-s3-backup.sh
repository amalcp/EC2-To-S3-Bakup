#############################################
#Server Backup To S3 Bucket using AWS CLI   #
#                         Created By ACP    #
#############################################
#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
SHELL=/bin/sh
LOGFILE="/var/log/dailybackp-s3.log"
date=$(date +"%d-%b-%Y")
db=mysql-$date.sql.gz
mdb=mongo-$date.zip
backup_path="/path/to/dir"
s3bucket="<BucketName>"

echo "\n Processing DB backup" >> $LOGFILE
source /path/to/.env #MySql Credentials
mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} --all-databases | gzip > ${backup_path}/${db}
if [ -e ${backup_path}/${db} ]; then
    # copy the current S3 files to new DIR
    aws s3 cp s3://${s3bucket}/latestfiles s3://${s3bucket}/www-$date --recursive
    # Sync EC2 Webfiles to S3
    aws s3 sync /var/www/ s3://${s3bucket}/latestfiles/ --delete
    # MySql Upload
    aws s3 cp ${backup_path}/${db} s3://${s3bucket}/mysql/${db}
        if [ "$?" -ne "0" ]; then
        echo "Upload to AWS failed" >> $LOGFILE
        exit 1
        fi
    # If success, remove backup file
    rm ${backup_path}/${db}
    exit 0
fi
echo "Backup Faild" >> $LOGFILE
exit 1
