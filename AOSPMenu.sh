#!/bin/bash





TEST_DIR_INP()
{
    echo $1
    read inp
    length=${#inp}
    ((length--))
    if [ $2 == "/" ]
    then
        while ! [ "${inp:$length:1}" == $2 ] 
        do
            echo "Input must end with a '/'"
            read inp
        done
        retval=$inp
    else
        while [ "${inp:$length:1}" == "/" ] 
        do
            echo "Input must NOT end with a '/'"
            read inp
        done
        retval=$inp
    fi
}


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

DISPLAY_SYSTEM_HEALTH()
{
    echo "Please Give Number of Passes (1-100)"
    read passes 
    CHECK_FOR_NUM_RANGE passes 1 100
    passes=$?
    echo "Please Give Time Interval (1s-50s)"
    read interval 
    CHECK_FOR_NUM_RANGE interval 1 50
    interval=$?
    sudo vmstat $interval $passes
    sudo vmstat -m
    sudo vmstat -d
    sudo vmstat -s
    sudo vmstat -a
}

SCHEDULE_ADDITIONAL_AUTO_TIMES()
{
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
    crontab crontabnew
    rm crontabnew
}


MANUAL_BACKUP()
{
    BACK_LOCATION="/home/LiveBackup"
    DIR_TO_BACK="/var/www/html/Live"
    BACK_NAME="$(date +'%d_%m_%Y')MANUAL"

    echo "BACKUP LIVE FOLDER? (y/n)"
    read Q_ANS
    if  ! [ "$Q_ANS" = "y" ] 
    then
        echo "SPECIFY DIRECTORY TO BACKUP (/path/to/folder)"
        read DIR_TO_BACK
        while ! [ -d "$DIR_TO_BACK" ]
        do
            echo "PATH NOT FOUND PLEASE SPECIFY DIRECTORY TO BACKUP (/path/to/folder)"
            read DIR_TO_BACK
        done

        echo "SPECIFY BACKUP LOCATION (/path/to/folder)"
        read BACK_LOCATION
        while ! [ -d "$BACK_LOCATION" ]
        do
            echo "PATH NOT FOUND PLEASE SPECIFY BACKUP LOCATION (/path/to/folder)"
            read BACK_LOCATION
        done
    fi

    mkdir $BACK_LOCATION/$BACK_NAME
    sudo chmod -R 000 $DIR_TO_BACK
    rsync -avr $DIR_TO_BACK/ $BACK_LOCATION/$BACK_NAME
    sudo chmod -R 770 $DIR_TO_BACK
}



AUTO_SETUP()
{
    echo "BY AUTO SETUP YOU WILL DELETE ALL FILES IN THE DIRECTORIES: /var/www/html/Intranet AND /var/www/html/Live"
    echo "DO YOU WISH TO CONTINUE (y/n)"

    read Q_ANS
    
    if  ! [ "$Q_ANS" = "y" ] 
    then
        echo "ABORTING"
        return
    fi

    sudo rm -r /var/www/html/Intranet 
    sudo rm -r /var/www/html/Live

    sudo AutoM8.sh

}

PRINT_AUDIT()
{
    echo "SELECT AUDIT TO VIEW"
    sudo ls /home/AuditLogs/
    read LogSelect

    while ! [ -d "/home/AuditLogs/$LogSelect" ]
    do
        echo "Selection in valid"
        read LogSelect
        if [ "$LogSelect" == "q" ]
        then
            return
        fi
    done
    
    sudo ls /home/AuditLogs/$LogSelect
    options=("Intranet" "Live" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Intranet")
                    cat /home/AuditLogs/$LogSelect/IntranetAudit.txt
                ;;
            "Live")
                    cat /home/AuditLogs/$LogSelect/LiveAudit.txt
                ;;
            "Quit")
                break
                ;;
            *) echo "invalid option";;
        esac
    done
}


ADD_USER_TO_STAFF()
{
    awk -F':' '{ print $1}' /etc/passwd
    echo "Please select a user to add to staff"
    read user_name
    sudo usermod -aG staff $user_name
}


SEND_MAIL()
{
    sudo apt install mailutils
    echo "Please input file to email"
    read fileselection
    while ! [ -f "$fileselection" ]
    do
        echo "File not found, please reenter or abort (q)"
        read fileselection
        if [ "$fileselection" == "q" ]
        then
            return  
        fi 
    done

    echo "Please input email to send to."
    read email
    echo "Please enter a subject for the email."
    read subject

    mail -s "$subject" $email < $fileselection
}

#           FUNTCIONALITY OF PROGRAM
#-----------------------------------------------------------
# 1.    Auto Setup (should install and set up automated tasks):
#                   - Install Apache
#                   - Creat Folders and Assign Groups
#                   - Install AuditD
#                   - Schedule Cronjob for Backup/Syncing/Auditing/System Health Monitoring
# 2.    Manual Backup (User should be able to create manual backups for the Live Folder as well as other folders that they desire)
# 3.    Print Audits (User should be able to display audits for particular time range)
# 4.    Manual Sync Intranet to Live
# 5.    Manual System Health Report
# 6.    List and Display all Automated Logs
# 7.    Add Additional Automated times
# 8.    Add user to staff group
# 9.    Mail text file to email address


PS3="##### PLEASE SELECT AN OPTION ######"
options=("Auto Setup System" "Backup Now" "Print Audit" "Manual Sync Intranet and Live" "Display Live System Health" "Schedule Additional Automated Tasks" "Add User to Staff Group" "Send To Mail" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Auto Setup System")
                AUTO_SETUP
            ;;
        "Backup Now")
                MANUAL_BACKUP
            ;;
        "Print Audit")
                PRINT_AUDIT
            ;;
        "Manual Sync Intranet and Live")
                echo "Perform backup before syncing? (y / n)"
                read sync
                if ! [ "$sync" == "n" ]
                then
                    MANUAL_BACKUP   
                fi
                sudo chmod -R 000 /var/www/html/Live
                sudo chmod -R 000 /var/www/html/Intranet
                rsync -rav --log-file=/home/AuditLogs/$(date +'%d_%m_%Y')/manualsyncintralivelog.txt /var/www/html/Intranet/ /var/www/html/Live
                sudo chmod -R 770 /var/www/html/Live
                sudo chmod -R 770 /var/www/html/Intranet
            ;;
        "Display Live System Health")
                DISPLAY_SYSTEM_HEALTH
            ;;
        "Schedule Additional Automated Tasks")
                SCHEDULE_ADDITIONAL_AUTO_TIMES 
            ;;
        "Add User to Staff Group")
                ADD_USER_TO_STAFF 
            ;;
        "Send To Mail")
                SEND_MAIL
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

