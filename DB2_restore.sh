#Master Restore Script
#################################################
#1. check if file has arrived in /beacon/SpyGlassDB/backup/full directory
#2. if file has arrived, run full restore.
#3. Move full back up file from /backup/full to backup/last_full_back_up ull folder
#############################################################################################################################
SrcFullBackupPath=/beacon/SpyGlassDB/backup/full
SrcIncrBackupPath=/beacon/SpyGlassDB/backup/incremental
backuppath=/beacon/SpyGlassDB/backup
ScriptDir=/home/db2admin/backup_proj
LastfullBackupPath=/beacon/SpyGlassDB/backup/lastfullbackup
#############################################################################################################################
#   FULL RESTORE
#############################################################################################################################
if [ ! -d "$backuppath/lastfullbackup" ]
then
   mkdir "$backuppath/lastfullbackup"
fi

if [ ! -d "$backuppath/processed/full" ]
then
   mkdir "$backuppath/processed"
   mkdir "$backuppath/processed/full"
fi

if [ ! -d "$backuppath/processed/incremental" ]
then
   mkdir "$backuppath/processed/incremental"
fi

#################################################################################################
if [ -e "$SrcFullBackupPath" ]
then
   fullbackupfile=$(ls -1r $SrcFullBackupPath | head -1)
   fullbackuptimestamp=$(ls -1r $SrcFullBackupPath | head -1 | cut -d'.' -f 5)
fi
###########################################################################################################################

if [ "$fullbackuptimestamp" > 0 ]
then
   echo "file has arrived and running restore "

   $ScriptDir/restore_full_V1.sh $fullbackuptimestamp $SrcFullBackupPath
   ret_code=$?
   echo "restore return code is $ret_code"
else
   echo "Full back up file has not arrived"
   exit
fi
###########################################################################################################################
if [ "$ret_code" == "0" ]
then
     mv $backuppath/lastfullbackup/*  $backuppath/processed/full
     mv $backuppath/full/$fullbackupfile  $backuppath/lastfullbackup
     $ScriptDir/cleanup_old.sh $fullbackuptimestamp $SrcfullBackupPath
fi

#############################################################################################
Incremental Restore
######################################################################################################
#1. Check timestamp of latest full back up file in /last_full_backup
#2. Check timestamp of latest incremental back up file.
#3. If incremental back up timestamp is after last full backup, then only run incremental restore
#4. After successful incremental restore, move incremental back up file to /processed/incremental folder.
########################################################################################
if [ -e "$LastfullBackupPath" ]
then
   fulltimestamp=$(ls -1r $LastfullBackupPath | head -1 |cut -d'.' -f 5)
   fullbackupfile=$(ls -1r $LastfullBackupPath | head -1)
   echo "last full backup timestamp : $fulltimestamp"
   echo " last ful back up file : $fullbackupfile"
fi
##########################################################################################
if [ -e "$SrcIncrBackupPath" ]
then
   incrtimestamp=$(ls -1r $SrcIncrBackupPath | head -1 |cut -d'.' -f 5)
   incrbackupfile=$(ls -1r $SrcIncrBackupPath | head -1)
   echo "restore to $incrtimestamp"
   echo " incremental back up file is $incrbackupfile"
else
   echo "Incremental backup file has not arrived"
   exit
fi

timediff=`expr $incrtimestamp - $fulltimestamp`

echo "time difference is $timediff"

if [ "$timediff" > 0 ] && [ -e "$LastfullBackupPath" ]
then
   echo " running incremental restore from back up taken at $incrtimestamp"


   $ScriptDir/restore_incremental_v1.sh $incrtimestamp $fulltimestamp $LastfullBackupPath $SrcIncrBackupPath
   ret_code_incr=$?
   if [ "$ret_code_incr"  == "0" ]
   then
       echo " Incremental Restore Successful"
       mv $SrcIncrBackupPath/$incrbackupfile $backuppath/processed/incremental
       $ScriptDir/cleanup_old.sh $incrtimestamp $SrcIncrBackupPath
   fi
else
  echo "Incremental back up file has not arrived"
fi
exit

