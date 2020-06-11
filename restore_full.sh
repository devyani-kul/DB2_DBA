#Directory Paths
SrcBackupPath=/beacon/SpyGlassDB/backup/full
DbPath=/beacon/SpyGlassDB/Data
Logtarget=/beacon/SpyGlassDB/logtarget
destdir=/home/db2admin/backup_proj

##Parameters for Source and Target DB
SrcDB=QAPROD
TargetDB=QA81


if [ -d "$Logtarget" ]
then
    echo "Directory $Logtarget exists."
    rm  -r $Logtarget

else
   echo "logtarget directory does not exist"
fi

mkdir $Logtarget
chown db2admin $Logtarget

echo "DB2 Restore From Full Online back up with Logs"

#Read restore timestamp from most recent full back up file.
################################################################################################33
timestamp1=$(ls -1r $SrcBackupPath | head -1 |cut -d'.' -f 5)
backupfile=$(ls -1r $SrcBackupPath | head -1)

#Display all paths to console
#############################################################################################
echo "$backupfile"
echo "$timestamp1"

echo "$SrcBackupPath"
echo "$DbPath"
echo "$Logtarget"
echo "$destdir"

echo "Full Restore of $TargetDB from $SrcDB taken at $timestamp1"
##############################################################################
#db2 -v -f$destdir/restore_full.db2 -z$destdir/restore_full.log

db2 connect to $TargetDB
db2 RESTORE DATABASE $SrcDB FROM $SrcBackupPath TAKEN AT $timestamp1 ON $DbPath INTO $TargetDB LOGTARGET $Logtarget  REDIRECT WITHOUT PROMPTING >>$destdir/restore_full.log
db2 SET STOGROUP PATHS FOR IBMSTOGROUP ON $DbPath >>$destdir/restore_full.log
db2 restore DATABASE $SrcDB CONTINUE >>$destdir/restore_full.log

returnCode=$?

if [ "$returnCode" != "0" ]
then
   echo "QAPROD BackUp failed : $returnCode"
else
   echo "QAPROD Online DB2 BACKUP  : $returnCode"
fi

##########################################################################################################################
db2 rollforward db $TargetDB to end of logs overflow log path "( $Logtarget )" NORETRIEVE >>$destdir/restore_full.log
db2 rollforward db $TargetDB stop overflow log path "( $Logtarget )" >>$destdir/restore_full.log
##########################################################################################################################
returnCode=$?

exit $returnCode
