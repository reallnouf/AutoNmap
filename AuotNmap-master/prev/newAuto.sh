#!/bin/sh


# ANSI colors for Auto-nmap-Analyzer
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[36m'
GREEN='\033[0;32m'
NC='\033[0m'
BLUE='\033[0;34m'
origIFS="${IFS}"
REMOTE='off'
# Start timer
elapsedStart="$(date '+%H:%M:%S' | awk -F: '{print $1 * 3600 + $2 * 60 + $3}')"

HOST="192.168.100.16"
TYPE='PORT'
#export output to file
#OUTPUTDIR="${HOST}"
#outputFile="$(echo $1 | sed -e 's/.*-oN \(.*\).nmap.*/\1/').nmap"
#tmpOutputFile="${outputFile}.tmp"

header() {
        echo
        # Print scan type
        printf "${CYAN}\t\t **** Auto-Nmap Analyzer **** \n\n"
        printf "${CYAN}\t **** SEC-505 (Network Security) Project **** \n\n"
        printf "${BLUE}Running a ${TYPE} scan on ${NC}${HOST}\n\n"
}


# Port Nmap port scan
portScan() {
        printf "${GREEN}---------------------Starting Port Scan-----------------------\n"
        printf "${NC}\n"
    
    if [ -e results ];
    then
    rm results
    fi
    
      nmap $HOST | tail -n +5 |head -n -3 >> results



      while read line
      do
      if [ line  = "open" ] && [ line  = "http" ];
then
      whatweb $HOST -v > temp
     fi
done <results

if [ -e temp ];
then
cat temp >> results
rm temp
fi

cat results | tr -s '[:blank:]' ',' > ofile.csv


}

# Print footer with total elapsed time
footer() {

        printf "${GREEN}---------------------Finished all scans------------------------\n"
        printf "${NC}\n\n"

}


# Choose run type based on chosen flags
        assignPorts "${HOST}"

        header
portScan


        footer
