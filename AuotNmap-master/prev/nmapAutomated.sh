#! /bin/bash
target='192.168.100.16'
# ANSI colors for Auto-nmap-Analyzer
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[36m'
GREEN='\033[0;32m'
NC='\033[0m'
BLUE='\033[0;34m'
#origIFS="${IFS}"
OUTPUTDIR="${target}"


header() {
        echo
        # Print scan type
        printf "${CYAN}\t\t **** Auto-Nmap Analyzer **** \n\n"
        printf "${CYAN}\t **** SEC-505 (Network Security) Project **** \n\n"
        printf "${YELLOW}Running a port scan on ${target}\n\n"
        printf "${NC}\n\n"
}

progress() {
        
echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
}

progressBar() {
        [ -z "${2##*[!0-9]*}" ] && return 1
        [ "$(stty size | cut -d ' ' -f 2)" -le 120 ] && width=50 || width=100
        fill="$(printf "%-$((width == 100 ? $2 : ($2 / 2)))s" "#" | tr ' ' '#')"
        empty="$(printf "%-$((width - (width == 100 ? $2 : ($2 / 2))))s" " ")"
        printf "In progress: $1 Scan ($3 elapsed - $4 remaining)   \n"
        printf "[${fill}>${empty}] $2%% done   \n"
        printf "\e[2A"
}

# Calculate current progress bar status based on nmap stats (with --stats-every)
# $1 is nmap command to be run, $2 is progress bar $refreshRate

nmapProgressBar() {
        refreshRate="${2:-1}"
        outputFile="$(echo $1 | sed -e 's/.*-oN \(.*\).nmap.*/\1/').nmap"
        tmpOutputFile="${outputFile}.tmp"
    
        # Print final output, remove extra nmap noise
                sed -n '/PORT.*STATE.*SERVICE/,/^# Nmap/H;${x;s/^\n\|\n[^\n]*\n# Nmap.*//gp}' "${outputFile}" | awk '!/^SF(:|-).*$/' | grep -v 'service unrecognized despite'

        rm -f "${tmpOutputFile}"
}

# Print footer with total elapsed time
footer() {
        printf "${NC}\n"
        printf "${CYAN}---------------------Finished all scans------------------------\n"
        printf "${NC}\n\n"

        elapsedEnd="$(date '+%H:%M:%S' | awk -F: '{print $1 * 3600 + $2 * 60 + $3}')"
        elapsedSeconds=$((elapsedEnd - elapsedStart))

        if [ ${elapsedSeconds} -gt 3600 ]; then
                hours=$((elapsedSeconds / 3600))
                minutes=$(((elapsedSeconds % 3600) / 60))
                seconds=$(((elapsedSeconds % 3600) % 60))
                printf "${GREEN}Completed in ${hours} hour(s), ${minutes} minute(s) and ${seconds} second(s)\n"
        elif [ ${elapsedSeconds} -gt 60 ]; then
                minutes=$(((elapsedSeconds % 3600) / 60))
                seconds=$(((elapsedSeconds % 3600) % 60))
                printf "${GREEN}Completed in ${minutes} minute(s) and ${seconds} second(s)\n"
        else
                printf "${GREEN}Completed in ${elapsedSeconds} seconds\n"
        fi
        printf "${NC}\n"
}


header
elapsedStart="$(date '+%H:%M:%S' | awk -F: '{print $1 * 3600 + $2 * 60 + $3}')"
Nmap ${target}

        # Print final output, remove extra nmap noise
progressBar
nmapProgressBar
footer
