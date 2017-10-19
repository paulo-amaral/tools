#!/bin/bash
#-------------------------------------------------------
#SCRIPT BACKUP DATABASES MYSQL
#Paulo Amaral
#Date - 16.10.2017
#This script send e-mail log after backup databases
#Please install Mailx to send email or another
#This script copy all databases in separated file
#--------------------------------------------------------------------------

#Mail Settings ( to send logfile )
EMAIL_ACCOUNT_PASSWORD="xxxx"
TO_EMAIL_ADDRESS=""
TO_EMAIL_ADDRESS_COPY=""
FROM_EMAIL_ADDRESS=""
FRIENDLY_NAME="BACKUP DB"
MAIL_SUBJECT="BACKUP MYSQL DATABASES"
SMTP_SERVER=""
SMTP_PORT="587" #use port 587/465/25
SMTP_URL="smtp://$SMTP_SERVER:$SMTP_PORT"

#Location to place backups.
backup_db="/opt/backups/"
current_date=`date '+%d%m%Y'`
timeslot=`date '+%H-%M'`
time=`date '+%T %x'`
logfile="$backup_db/log_backup_$current_date.log"

# MySQL settings
user=""
password=''
export host=localhost
export host_name=`hostname`
mysqldump="$(which mysqldump)"

# Get MySQL databases
databases=$(mysql --user=$user -p$password -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)")

#create backup folder
if [ ! -d $backup_db/$current_date ]
then
   mkdir  -p $backup_db/$current_date || exit
fi

#Backup Database and send mail for admin
backup_db(){
        echo  "START DATABASE DUMP AT $time " >> $logfile
for db in $databases; do
        timeinfo=`date '+%T %x'`
  	      echo "Creating backup of \"${db}\" database"
              $mysqldump --single-transaction --events --skip-lock-tables --ignore-table=mysql.event \
              -h $host --user=$user  -p$password $db | gzip > $backup_db$current_date/$db.gz
       		 if [ "$?" -eq "0" ]; then
        	    echo "Dump database MYSQL complete at $timeinfo for time slot $timeslot on database: $db " >> $logfile
                 else
                    echo "##### WARNING: #####  $i backup failed"  >> $logfile
       		   exit 1
  		fi
done
        echo  "FINISH DATABASE DUMP AT $time " >> $logfile
}


#Check Mailx Package
check_mailx() {

    echo -e "Checking if Mailx is installed\n"
    echo    "--------------------------------"
    MAILX=$(which mailx | wc -l)
    if [ $MAILX -eq 0 ] ; then
        echo "Mailx not installed - Installing now - Please wait \n"
        apt-get install -y  heirloom-mailx
    else
        echo "Mailx is installed "
    fi
    return 0
}

send_mail() {
 #Send E-mail with backup results
  cat $logfile | mailx -v -s "$MAIL_SUBJECT" -c "$TO_EMAIL_ADDRESS_COPY" \
  -S smtp-use-starttls \
  -S ssl-verify=ignore \
  -S smtp-auth=plain \
  -S smtp=$SMTP_URL \
  -S from="$FROM_EMAIL_ADDRESS($FRIENDLY_NAME)" \
  -S smtp-auth-user=$FROM_EMAIL_ADDRESS \
  -S smtp-auth-password=$EMAIL_ACCOUNT_PASSWORD \
  -S ssl-verify=ignore \
  $TO_EMAIL_ADDRESS > /dev/null
}


#Delete old logfile
delete_log(){
TIME_DEL='+10'
find $logfile -name "*.log" -ctime $TIME_DEL -exec rm -f {} ";"
find $backup_db/* -mindepth 1 -maxdepth 1 -type d -ctime $TIME_DEL | xargs rm -rf
}

backup_db
check_mailx
send_mail
delete_log



