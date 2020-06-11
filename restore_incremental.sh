#Directory Paths
###################################################################33
SrcFullBackupPath=/beacon/SpyGlassDB/backup/lastfullbackup
SrcIncrBackupPath=//beacon/SpyGlassDB/backup/incremental
DbPath=/beacon/SpyGlassDB/Data
Logtarget=/beacon/SpyGlassDB/full/logtarget
IncrLogtarget=/beacon/SpyGlassDB/incremental/logtarget
destdir=/home/db2admin/backup_proj
#####################################################################
##Parameters for Source and Target DB
SrcDB=QAPROD
TargetDB=QA81
########################################################################

if [ -d "$Logtarget" ]
then
    echo "Directory $Logtarget exists."
    rm  -r $Logtarget

else
   echo "$Logtarget directory does not exist"
fi

if [ -d "$IncrLogtarget" ]
then
    echo "Directory $Logtarget exists."
    rm  -r Incr$Logtarget

else
   echo "$IncrLogtarget directory does not exist"
fi

###Create Logtarget Directory to retrieve logs from backup
mkdir $Logtarget
mkdir $IncrLogtarget
chown db2admin $Logtarget
chown db2admin $IncrLogtarget
#########################################################################################
echo "DB2 Incremental Restore "
########################################################################################
#Read restore timestamp from most recent full back up file.

fulltimestamp=$(ls -1r $SrcFullBackupPath | head -1 |cut -d'.' -f 5)
fullbackupfile=$(ls -1r $SrcFullBackupPath | head -1)

incrtimestamp=$(ls -1r $SrcIncrBackupPath | head -1 |cut -d'.' -f 5)
incrbackupfile=$(ls -1r $SrcIncrBackupPath | head -1)

############################################################################################
############################################################################################
#Display restore Sequence and Paths
echo "Restore Sequence is : $incrtimestamp -> $fulltimestamp -> $incrtimestamp"

echo "$DbPath"
echo "$Logtarget"
echo "$destdir"
########################################################################################
echo "Incremental Restore of $TargetDB from $SrcDB"
#################################################################################################
db2 connect to $TargetDB
db2 prune history 9999 with force option
db2 connect reset

db2 connect to $TargetDB

db2 force applications all

db2 Restore db $SrcDB INCREMENTAL from $SrcIncrBackupPath  taken at $incrtimestamp  ON $DbPath INTO $TargetDB LOGTARGET $IncrLogtarget REDIRECT WITHOUT PROMPTING >>$destdir/restore_incremental.log

db2 SET STOGROUP PATHS FOR IBMSTOGROUP ON $DbPath >>$destdir/restore_incremental.log

db2 RESTORE DATABASE $SrcDB  CONTINUE >>$destdir/restore_incremental.log
########################################################################################################################################
echo "Redirect Restore phase complete. Continuing with remaining phases"

db2 RESTORE DB $SrcDB INCREMENTAL FROM $SrcFullBackupPath  taken at $fulltimestamp INTO $TargetDB LOGTARGET $Logtarget  WITHOUT PROMPTING >>$destdir/restore_incremental.log
db2 RESTORE DB $SrcDB INCREMENTAL FROM $SrcIncrBackupPath taken at $incrtimestamp INTO $TargetDB LOGTARGET $IncrLogtarget WITHOUT PROMPTING >>$destdir/restore_incremental.log

returnCode=$?


if [ "$returnCode" != "0" ]
then
   echo "QA81 Restore failed : $returnCode"
else
   echo "QA81 Restore Successful : $returnCode"
fi

mv $IncrLogtarget/* $Logtarget
##########################################################################################################################
#RollForward database to end of the logs to bring backup database up and live
#################################################################################################################################
db2 rollforward db $TargetDB to end of logs overflow log path "( $Logtarget )" NORETRIEVE >>$destdir/restore_incremental.log
db2 rollforward db $TargetDB stop overflow log path "( $Logtarget )" NORETRIEVE  >>$destdir/restore_incremental.log

returnCode1=$?
echo "Rollforward completed with RC : $returnCode1"
exit $returnCode1
