#!/bin/bash

#just verifying that the number input is correct format i.e. is an integer within range
CHECK_FOR_NUM_RANGE() 
{
    input=$(($1))
    if ! [[ "$(($1))" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
    then
        while ! [[ "$(($1))" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
        do
            echo "Sorry integers only"
            read input
        done
    fi
    while [ $input -lt $2 ] || [ $input -gt $3 ]
    do
        echo "Please Enter a Number between $2 and $3 "
        read input
        while ! [[ "$input" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
        do
            echo "Sorry integers only"
            read input
        done
    done
    return $input
}


#first time setup
#create staff group, no need to create a separate admin group since sudo already exists
sudo groupadd staff

#we are working under the assumption that apache2 is already installed, but just in case we install it here
sudo apt install apache2
sudo apt-get install acl

sudo mkdir -m770 /var/www/html/Intranet #making a directory for the Intranet Site 
sudo chown $USER /var/www/html/Intranet
sudo touch /var/www/html/Intranet/index_test.html # ---------------------------------------------------------------------<TESTING_INTRA/LIVE_SYNC_SYSTEM>
sudo chgrp -R staff /var/www/html/Intranet

sudo mkdir -m770 /var/www/html/Live #making a directory for the Live Site
sudo chown $USER /var/www/html/Live
sudo touch /var/www/html/Live/BACKUP_SYSTEM_TEST.txt # ---------------------------------------------------------------------<TESTING_LIVE_BACKUP_SYSTEM>
sudo chgrp -R sudo /var/www/html/Live

sudo mkdir -m770 /home/LiveBackup #making a directory for the Backup Folder
sudo chown $USER /home/LiveBackup
sudo chgrp -R sudo /home/LiveBackup

sudo mkdir -m770 /home/AuditLogs
sudo chown $USER /home/AuditLogs
sudo chgrp -R sudo /home/AuditLogs

sudo mkdir -m770 /home/SysHealthLogs
sudo chown $USER /home/SysHealthLogs
sudo touch /home/SysHealthLogs/HealthLog.txt
sudo chgrp -R sudo /home/SysHealthLogs


sudo apt-get install auditd
sudo service auditd start
sudo systemctl enable auditd
sudo auditctl -w /var/www/html/Intranet -p rwxa #placing an audit on Intranet Folder
sudo auditctl -w /var/www/html/Live -p rwxa #placeing an audit on Live Folder (not specified in brief but might be useful anyway)


echo "PLEASE INPUT MINUTE (0-59)"
read minInput
CHECK_FOR_NUM_RANGE minInput 0 59
minInput=$?
echo "PLEASE INPUT HOUR (0-23)"
read hourInput 
CHECK_FOR_NUM_RANGE hourInput 0 23
hourInput=$?

crontab -l > crontabnew
echo "$minInput $hourInput * * * /usr/bin/BackupAndSyncProgram.sh /var/www/html/Intranet /var/www/html/Live /home/LiveBackup /home/AuditLogs" >> crontabnew
echo "$minInput $hourInput * * * /usr/bin/SysHealthMonitor.sh /home/SysHealthLogs/HealthLog.txt" >> crontabnew
crontab crontabnew
rm crontabnew



#-------------------------------------------------------------BRIEF----------------------------------------------------------------------------------------
#1. The company will have an internal Intranet site that is a duplicate copy of the live website. Staff can make changes to the Intranet 
#   version of the site and see the changes before it goes live. (This will help prevent content issues and page availability issues for users of the site). 

#2. The website content should be backed up every night. 

#3. The changes made to the Intranet version of the site needs to documented. The username of the user, the page they modified and the 
#   timestamp should be recorded. (the Auditd daemon can be used for this) 

#4. The live site needs to be updated based on the changes made to the Intranet site. This should happen during the night. There are a 
#   large number of files on the website (5000+), only the files that have changed should be copied to the live site folder. 

#5. No changes should be allowed to be made to the site while the backup/transfer is happening. 

#6. If a change needs to be urgently made to the live site, it should be possible to make the changes. (Users shouldn’t have write access to 
#   the new website folder) 