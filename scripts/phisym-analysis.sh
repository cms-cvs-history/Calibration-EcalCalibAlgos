#! /bin/bash
#

#
# script to run the complete phisym calibration exercise
# S.A. Sept 22, 2008
#

if [ $# -ne 4 ] 
then
    echo "Usage $0 conffile runlist destserver destdir"
    exit 
fi

conffile=$1
runlist=$2
destserver=$3
destdir=$4

nfilesperjob=5

#evaluate number of jobs
nfiles=`wc $runlist | awk '{print $1}'` 
njobs=`echo $[nfiles/$nfilesperjob]` 

echo "$0: starting at `date`"
echo "$0: $nfiles files to process in $njobs jobs" 

#were to store output
datadir=$destdir/$1-$2
echo "$0: output will be stored in $datadir"

#generated by 'scram runt -sh > cmsenv.sh' 
#source cmsenv.sh 
eval `scram runt -sh`

#create target dir
ssh $destserver mkdir -p $datadir

echo "$0: Removing old files"
rm -rf *.dat 
rm -rf *.root
rm -rf *.log

echo "$0: Submitting jobs"
./phisym-submit.py -c $conffile -r $runlist -n $njobs -e $destserver:$datadir 


#wait for jobs to finish (look if there's any config file left)
while [ "`ls config* 2>/dev/null`" != "" ] ; do  
   sleep 1
done


#join etsum files
cat etsum_barl_*.dat > etsum_barl.dat
cat etsum_endc_*.dat > etsum_endc.dat
rm  etsum_barl_*.dat
rm  etsum_endc_*.dat



#run calibration job
cmsRun  phisym-calibration.cfg > output-$1-$2.log
scp -r *.root *.dat *.log $destserver:$datadir
scp -r ../src $destserver:$datadir

#cleanup*
rm -f *.dat
rm -f *.root

echo "$0: finishing at `date`"
