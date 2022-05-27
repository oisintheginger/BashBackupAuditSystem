#!/bin/bash
intra=$1
live=$2
back=$3
auditdir=$4
dateDir=$(date +'%d_%m_%Y') 



sudo mkdir $auditdir/$dateDir 
sudo chmod -R 770 $auditdir/$dateDir
sudo chown $USER  $auditdir/$dateDir
sudo chgrp -R sudo $auditdir/$dateDir

sudo ausearch --input-logs -f $intra -i >> $auditdir/$dateDir/IntranetAudit.txt
sudo ausearch --input-logs -f  $live -i >> $auditdir/$dateDir/LiveAudit.txt

sudo mkdir $back/$dateDir #making a backup directory for the specified date
sudo chmod -R 770 $back/$dateDir
sudo chown $USER  $back/$dateDir
sudo chgrp -R sudo $back/$dateDir

sudo chmod -R 000 $intra 
sudo chmod -R 000 $live 
rsync -rav --log-file=$auditdir/$dateDir/backuptransferlog.txt $live $back/$dateDir
rsync -rav --log-file=$auditdir/$dateDir/intralivesynclog.txt $intra/ $live
sudo chmod -R 770 $intra
sudo chmod -R 770 $live
