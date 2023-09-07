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

#Files
outDir="/Users/tamimisu/Desktop/NmapProject"
csvFile="AnalyzeMe.csv"
sourceFile ="/Users/tamimisu/Desktop/NmapProject/out.txt"

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


# $1 is $scanType, $2 is $percent, $3 is $elapsed, $4 is $remaining
progressBar() {
        [ -z "${2##*[!0-9]*}" ] && return 1
        [ "$(stty size | cut -d ' ' -f 2)" -le 120 ] && width=50 || width=100
        fill="$(printf "%-$((width == 100 ? $2 : ($2 / 2)))s" "#" | tr ' ' '#')"
        empty="$(printf "%-$((width - (width == 100 ? $2 : ($2 / 2))))s" " ")"
        printf "In progress: $1 Scan ($3 elapsed - $4 remaining)   \n"
        printf "[${fill}>${empty}] $2%% done   \n"
        printf "\e[2A"
}


# Used Before and After each nmap scan, to keep found ports consistent across the script
# $1 is $HOST
assignPorts() {
        # Set $commonPorts based on Port scan
        if [ -f "nmap/Port_$1.nmap" ]; then
                commonPorts="$(awk -vORS=, -F/ '/^[0-9]/{print $1}' "nmap/Port_$1.nmap" | sed 's/.$//')"
        fi

        # Set $allPorts based on Full scan or both Port and Full scans
        if [ -f "nmap/Full_$1.nmap" ]; then
                if [ -f "nmap/Port_$1.nmap" ]; then
                        allPorts="$(awk -vORS=, -F/ '/^[0-9]/{print $1}' "nmap/Port_$1.nmap" "nmap/Full_$1.nmap" | sed 's/.$//')"
                else
                        allPorts="$(awk -vORS=, -F/ '/^[0-9]/{print $1}' "nmap/Full_$1.nmap" | sed 's/.$//')"
                fi
        fi
}


# Port Nmap port scan
portScan() {
        printf "${GREEN}---------------------Starting Port Scan-----------------------\n"
        printf "${NC}\n"
        assignPorts "${HOST}"

        echo
        echo
        echo
}

function fnGnmapToCsv {
  # Reduce file to lines with open ports to eliminate reading unnecessary lines
  grep '/open/' "$sourceFile" --color=never > "$outDir"/".txt"
  # Convert to CSV
  while read -r thisLine; do
    # Get host address
    thisHost=$(echo "$thisLine" | awk '{print $outDir}')
    # Parse open port results
    echo "$thisLine" | awk '{$1=$2=$3=$4=""; print $0}' | sed 's/\/,/\/\n/g' | sed 's/^ *//g' | grep '/open/' | awk -v awkHost="$thisHost" -F / '{print awkHost "," $3 "," $1 "," $5 "," $7}' | awk -F \( '{print $1}' | sed 's/,$//g' >> "$outDir"/"working-csv.txt"
  done < "$outDir"/"working-src.txt"
  if [ -f "$outDir"/"working-src.txt" ]; then rm "$outDir"/"working-src.txt"; fi
  # Convert unsorted working CSV into sorted final CSV
  sort -Vu "$outDir"/"working-csv.txt" | grep -v "tcpwrapped" > "$outDir"/"$csvFile"
  if [ -f "$outDir"/"working-csv.txt" ]; then rm "$outDir"/"working-csv.txt"; fi
}


# Print footer with total elapsed time
footer() {

        printf "${GREEN}---------------------Finished all scans------------------------\n"
        printf "${NC}\n\n"

        elapsedEnd="$(date '+%H:%M:%S' | awk -F: '{print $1 * 3600 + $2 * 60 + $3}')"
        elapsedSeconds=$((elapsedEnd - elapsedStart))

        if [ ${elapsedSeconds} -gt 3600 ]; then
                hours=$((elapsedSeconds / 3600))
                minutes=$(((elapsedSeconds % 3600) / 60))
                seconds=$(((elapsedSeconds % 3600) % 60))
                printf "${BLUE}Completed in ${hours} hour(s), ${minutes} minute(s) and ${seconds} second(s)\n"
        elif [ ${elapsedSeconds} -gt 60 ]; then
                minutes=$(((elapsedSeconds % 3600) / 60))
                seconds=$(((elapsedSeconds % 3600) % 60))
                printf "${BLUE}Completed in ${minutes} minute(s) and ${seconds} second(s)\n"
        else
                printf "${BLUE}Completed in ${elapsedSeconds} seconds\n"
        fi
        printf "${NC}\n"
}


# Choose run type based on chosen flags
        assignPorts "${HOST}"

        header

        nmap ${HOST}
        nmap ${HOST} > AnalyzeMe.csv
        
#        fnGnmapToCsv
        # try to convert output to csv
     

        footer








