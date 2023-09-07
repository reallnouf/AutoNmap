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

# Parse flags
while [ $# -gt 0 ]; do
        key="$1"

        case "${key}" in
            -h)
                HOST="$2"
                shift
                shift
                ;;
            -t)
                TYPE="$2"
                shift
                shift
                ;;
            -o)
                OUTPUTDIR="$2"
                shift
                shift
                ;;
            *)
                POSITIONAL="${POSITIONAL} $1"
                shift
                ;;
        esac
done
set -- ${POSITIONAL}

# Set output dir or default to host-based dir
if [ -z "${OUTPUTDIR}" ]; then
        OUTPUTDIR="${HOST}"
fi


# Print usage menu and exit. Used when issues are encountered
usage() {
        echo
        printf "Scan Types:\n"
        printf "${YELLOW}\tNetwork : ${NC}Shows all live hosts in the host's network\n"
        printf "${YELLOW}\tPort    : ${NC}Shows all open ports\n"
        printf "${YELLOW}\tVulns   : ${NC}Runs CVE scan and nmap Vulns scan on all found ports\n"
        printf "${NC}\n"
        exit 1
}

# Print initial header and set initial variables before scans start

header() {
        echo
        # Print scan type
        printf "${CYAN}\t\t **** Auto-Nmap Analyzer **** \n\n"
        printf "${CYAN}\t **** SEC-505 (Network Security) Project **** \n\n"
        printf "${BLUE}Running a ${TYPE} scan on ${NC}${HOST}\n\n"
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



# Add any extra ports found in Full scan
# No args needed
cmpPorts() {
        extraPorts="$(echo ",${allPorts}," | sed 's/,\('"$(echo "${commonPorts}" | sed 's/,/,\\|/g')"',\)\+/,/g; s/^,\|,$//g')"
}

# Print nmap progress bar
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

# Calculate current progress bar status based on nmap stats (with --stats-every)
# $1 is nmap command to be run, $2 is progress bar $refreshRate
nmapProgressBar() {
        refreshRate="${2:-1}"
        outputFile="$(echo $1 | sed -e 's/.*-oN \(.*\).nmap.*/\1/').nmap"
        tmpOutputFile="${outputFile}.tmp"

        # Run the nmap command
        if [ ! -e "${outputFile}" ]; then
                $1 --stats-every "${refreshRate}s" >"${tmpOutputFile}" 2>&1 &
        fi

        # Keep checking nmap stats and calling progressBar() every $refreshRate
        while { [ ! -e "${outputFile}" ] || ! grep -q "Nmap done at" "${outputFile}"; } && { [ ! -e "${tmpOutputFile}" ] || ! grep -i -q "quitting" "${tmpOutputFile}"; }; do
                scanType="$(tail -n 2 "${tmpOutputFile}" 2>/dev/null | sed -ne '/elapsed/{s/.*undergoing \(.*\) Scan.*/\1/p}')"
                percent="$(tail -n 2 "${tmpOutputFile}" 2>/dev/null | sed -ne '/% done/{s/.*About \(.*\)\..*% done.*/\1/p}')"
                elapsed="$(tail -n 2 "${tmpOutputFile}" 2>/dev/null | sed -ne '/elapsed/{s/Stats: \(.*\) elapsed.*/\1/p}')"
                remaining="$(tail -n 2 "${tmpOutputFile}" 2>/dev/null | sed -ne '/remaining/{s/.* (\(.*\) remaining.*/\1/p}')"
                progressBar "${scanType:-No}" "${percent:-0}" "${elapsed:-0:00:00}" "${remaining:-0:00:00}"
                sleep "${refreshRate}"
        done
        printf "\033[0K\r\n\033[0K\r\n"

        # Print final output, remove extra nmap noise
        if [ -e "${outputFile}" ]; then
                sed -n '/PORT.*STATE.*SERVICE/,/^# Nmap/H;${x;s/^\n\|\n[^\n]*\n# Nmap.*//gp}' "${outputFile}" | awk '!/^SF(:|-).*$/' | grep -v 'service unrecognized despite'
        else
                cat "${tmpOutputFile}"
        fi
        rm -f "${tmpOutputFile}"
}

# Nmap scan for live hosts
networkScan() {
        printf "${GREEN}---------------------Starting Network Scan---------------------\n"
        printf "${NC}\n"

        origHOST="${HOST}"
        HOST="${urlIP:-$HOST}"
        if [ $kernel = "Linux" ]; then TW="W"; else TW="t"; fi

        if ! $REMOTE; then
                # Discover live hosts with nmap
                nmapProgressBar "${nmapType} -T4 --max-retries 1 --max-scan-delay 20 -n -sn -oN nmap/Network_${HOST}.nmap ${subnet}/24"
                printf "${YELLOW}Found the following live hosts:${NC}\n\n"
                cat nmap/Network_${HOST}.nmap | grep -v '#' | grep "$(echo $subnet | sed 's/..$//')" | awk {'print $5'}
        elif $pingable; then
                # Discover live hosts with ping
                echo >"nmap/Network_${HOST}.nmap"
                for ip in $(seq 0 254); do
                        (ping -c 1 -${TW} 1 "$(echo $subnet | sed 's/..$//').$ip" 2>/dev/null | grep 'stat' -A1 | xargs | grep -v ', 0.*received' | awk {'print $2'} >>"nmap/Network_${HOST}.nmap") &
                done
                wait
                sed -i '/^$/d' "nmap/Network_${HOST}.nmap"
                sort -t . -k 3,3n -k 4,4n "nmap/Network_${HOST}.nmap"
        else
                printf "${YELLOW}No ping detected.. TCP Network Scan is not implemented yet in Remote mode.\n${NC}"
        fi

        HOST="${origHOST}"

        echo
        echo
        echo
}

# Port Nmap port scan
portScan() {
        printf "${GREEN}---------------------Starting Port Scan-----------------------\n"
        printf "${NC}\n"

        if ! $REMOTE; then
                nmapProgressBar "${nmapType} -T4 --max-retries 1 --max-scan-delay 20 --open -oN nmap/Port_${HOST}.nmap ${HOST} ${DNSSTRING}"
                assignPorts "${HOST}"
        else
                printf "${YELLOW}Port Scan is not implemented yet in Remote mode.\n${NC}"
        fi

        echo
        echo
        echo
}



# Nmap scan on all ports
fullScan() {
        printf "${GREEN}---------------------Starting Full Scan------------------------\n"
        printf "${NC}\n"

        if ! $REMOTE; then
                nmapProgressBar "${nmapType} -p- --max-retries 1 --max-rate 500 --max-scan-delay 20 -T4 -v --open -oN nmap/Full_${HOST}.nmap ${HOST} ${DNSSTRING}" 3
                assignPorts "${HOST}"

                # Nmap version and default script scan on found ports if Script scan was not run yet
                if [ -z "${commonPorts}" ]; then
                        echo
                        echo
                        printf "${YELLOW}Making a script scan on all ports\n"
                        printf "${NC}\n"
                        nmapProgressBar "${nmapType} -sCV -p${allPorts} --open -oN nmap/Full_Extra_${HOST}.nmap ${HOST} ${DNSSTRING}" 2
                        assignPorts "${HOST}"
                # Nmap version and default script scan if any extra ports are found
                else
                        cmpPorts
                        if [ -z "${extraPorts}" ]; then
                                echo
                                echo
                                allPorts=""
                                printf "${YELLOW}No new ports\n"
                                printf "${NC}\n"
                        else
                                echo
                                echo
                                printf "${YELLOW}Making a script scan on extra ports: $(echo "${extraPorts}" | sed 's/,/, /g')\n"
                                printf "${NC}\n"
                                nmapProgressBar "${nmapType} -sCV -p${extraPorts} --open -oN nmap/Full_Extra_${HOST}.nmap ${HOST} ${DNSSTRING}" 2
                                assignPorts "${HOST}"
                        fi
                fi
        else
                printf "${YELLOW}Full Scan is not implemented yet in Remote mode.\n${NC}"
        fi

        echo
        echo
        echo
}



# Nmap vulnerability detection script scan
vulnsScan() {
        printf "${GREEN}---------------------Starting Vulns Scan-----------------------\n"
        printf "${NC}\n"

        if ! $REMOTE; then
                # Set ports to be scanned (common or all)
                if [ -z "${allPorts}" ]; then
                        portType="common"
                        ports="${commonPorts}"
                else
                        portType="all"
                        ports="${allPorts}"
                fi

                # Ensure the vulners script is available, then run it with nmap
                if [ ! -f /usr/share/nmap/scripts/vulners.nse ]; then
                        printf "${RED}Please install 'vulners.nse' nmap script:\n"
                        printf "${RED}https://github.com/vulnersCom/nmap-vulners\n"
                        printf "${RED}\n"
                        printf "${RED}Skipping CVE scan!\n"
                        printf "${NC}\n"
                else
                        printf "${YELLOW}Running CVE scan on ${portType} ports\n"
                        printf "${NC}\n"
                        nmapProgressBar "${nmapType} -sV --script vulners --script-args mincvss=7.0 -p${ports} --open -oN nmap/CVEs_${HOST}.nmap ${HOST} ${DNSSTRING}" 3
                        echo
                fi

                # Nmap vulnerability detection script scan
                echo
                printf "${YELLOW}Running Vuln scan on ${portType} ports\n"
                printf "${YELLOW}This may take a while, depending on the number of detected services..\n"
                printf "${NC}\n"
                nmapProgressBar "${nmapType} -sV --script vuln -p${ports} --open -oN nmap/Vulns_${HOST}.nmap ${HOST} ${DNSSTRING}" 3
        else
                printf "${YELLOW}Vulns Scan is not supported in Remote mode.\n${NC}"
        fi

        echo
        echo
        echo
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
main() {
        assignPorts "${HOST}"

        header

        case "${TYPE}" in
        [Nn]etwork) networkScan "${HOST}" ;;
        [Pp]ort) portScan "${HOST}" ;;
        [Ss]cript)
                [ ! -f "nmap/Port_${HOST}.nmap" ] && portScan "${HOST}"
                scriptScan "${HOST}"
                ;;
        [Ff]ull) fullScan "${HOST}" ;;
        [Uu]dp) UDPScan "${HOST}" ;;
        [Vv]ulns)
                [ ! -f "nmap/Port_${HOST}.nmap" ] && portScan "${HOST}"
                vulnsScan "${HOST}"
                ;;
        [Rr]econ)
                [ ! -f "nmap/Port_${HOST}.nmap" ] && portScan "${HOST}"
                [ ! -f "nmap/Script_${HOST}.nmap" ] && scriptScan "${HOST}"
                recon "${HOST}"
                ;;
        [Aa]ll)
                portScan "${HOST}"
                scriptScan "${HOST}"
                fullScan "${HOST}"
                UDPScan "${HOST}"
                vulnsScan "${HOST}"
                recon "${HOST}"
                ;;
        esac

        footer
}

# Ensure host and type are passed as arguments
if [ -z "${TYPE}" ] || [ -z "${HOST}" ]; then
        usage
fi

# Ensure $HOST is an IP or a URL
if ! expr "${HOST}" : '^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)$' >/dev/null && ! expr "${HOST}" : '^\(\([[:alnum:]-]\{1,63\}\.\)*[[:alpha:]]\{2,6\}\)$' >/dev/null; then
        printf "${RED}\n"
        printf "${RED}Invalid IP or URL!\n"
        usage
fi

# Ensure selected scan type is among available choices, then run the selected scan
if ! case "${TYPE}" in [Nn]etwork | [Pp]ort | [Ss]cript | [Ff]ull | UDP | udp | [Vv]ulns | [Rr]econ | [Aa]ll) false ;; esac then
        mkdir -p "${OUTPUTDIR}" && cd "${OUTPUTDIR}" && mkdir -p nmap/ || usage
        main | tee "nmapAutomator_${HOST}_${TYPE}.txt"
else
        printf "${RED}\n"
        printf "${RED}Invalid Type!\n"
        usage
fi
