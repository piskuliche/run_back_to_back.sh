#!/bin/bash

#This script is used to create a job that runs at a walltime of less than 6 hours.
#It does this by requesting a walltime of 6 hours, but then kills the job after 5 hours.
#It then produces a new job script, and submits it.

#USAGE: ./run_back_to_back.sh jobpreface startid endid
#jobpreface is the name of your input files i.e. jobpreface.start jobpreface.restart
#startid is the number of the run you want to start i.e. for a new run choose 1.
#endid is the number of the run you want to end on i.e. to run 30 iterations choose endid as 30.

#User Interface: 
sid=$2
lastid=$((sid-1))
rununtil=$3
#Creates a PBS Script for the current run
echo '#PBS -S /bin/bash' > $sid.sh
echo '#PBS -N '$1'.run'$sid >> $sid.sh
echo '#PBS -q default' >> $sid.sh
echo '#PBS -l nodes=1:ppn=6:intel' >> $sid.sh
echo '#PBS -l walltime=00:06:00:00' >> $sid.sh
echo '#PBS -j oe' >> $sid.sh
echo '#PBS -o '$1'-'$sid'.joblog' >> $sid.sh

echo 'cd $PBS_O_WORKDIR' >> $sid.sh
echo '# Save job specific info for troubleshooting' >> $sid.sh
echo 'echo "Running on host ${hostname}"' >> $sid.sh
echo 'echo "The following processors are allocated to this job"' >> $sid.sh
echo 'echo $(cat $PBS_NODEFILE)' >> $sid.sh

echo 'module load intel_compiler' >> $sid.sh
echo 'export OMP_NUM_THREADS=4' >> $sid.sh


echo 'echo "Start: $(date +%F_%T)"' >> $sid.sh
if [ "$sid" -eq "1" ]; then
    echo 'timeout 5h time Cassandra_1.2.4.exe '$1'.start' >> $sid.sh
else
    echo 'timeout 5h time Cassandra_1.2.4.exe '$1'.restart' >> $sid.sh
fi
echo 'echo "End: $(date +%F_%T)"' >> $sid.sh 
echo 'mkdir run-'$sid >> $sid.sh
echo 'gzip *.xyz' >> $sid.sh
echo 'mv *xyz *gz *prp *H *.log *.sh run-'$sid'/' >> $sid.sh
echo 'cp *chk run-'$sid'/' >> $sid.sh

#Determines whether to run again after the current run or not
nextid=$((sid+1))
if [ "$nextid" -lt "$rununtil" ]; then
    echo 'run_back_to_back.sh '$1' '$nextid' '$rununtil >> $sid.sh
else
    MESSAGE="This run needs checking: "$1
    echo $MESSAGE | mail -s "completion terminated" "piskuliche@ku.edu"
fi

#submits the job.
one=$(qsub $sid.sh)
