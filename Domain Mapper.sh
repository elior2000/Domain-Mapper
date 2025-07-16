#!/bin/bash
# Domain Mapper.sh - Elior Salimi
# Platform: Kali Linux

banner() {
cat << "EOF"
 ____                        _       __  __
|  _ \  ___  _ __ ___   __ _(_)_ __ |  \/  | ___ _ __ ___  ___
| | | |/ _ \| '_ ` _ \ / _` | | '_ \| |\/| |/ _ \ '__/ __|/ _ \
| |_| | (_) | | | | | | (_| | | | | | |  | |  __/ |  \__ \  __/
|____/ \___/|_| |_| |_|\__,_|_|_| |_|_|  |_|\___|_|  |___/\___|
                  Domain Mapper by Elior Salimi
EOF
}

help_menu() {
cat << EOF
Domain Mapper - Help Menu

This tool helps map and analyze domain networks using automation.

Features:
- Scanning (multiple levels)
- Enumeration (including AD objects)
- Exploitation & Weakness checks
- PDF reporting

Usage: Run the script and follow the on-screen Wizard.
Requirements: Kali Linux, nmap, hydra, enum4linux, rpcclient, sipcalc, enscript, ghostscript (ps2pdf), crackmapexec (optional)
EOF
}

progress() {
    local step="$1"
    local msg="$2"
    echo -e "\n\033[1;34m[*] [$step] $msg\033[0m"
    sleep 1
}

check_tools() {
    required_tools=("nmap" "hydra" "enum4linux" "rpcclient" "sipcalc" "python3" "enscript" "ps2pdf" "git")
    missing=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1 && ! dpkg -s "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "\n\033[1;31m[!] The following required tools are missing:\033[0m"
        for tool in "${missing[@]}"; do
            echo "   - $tool"
        done
        read -rp $'\nDo you want to attempt automatic installation of these tools now? (Y/n): ' answer
        answer=${answer,,}
        if [[ "$answer" =~ ^(y|yes|)$ ]]; then
            for tool in "${missing[@]}"; do
                case "$tool" in
                    "enscript")
                        sudo apt update && sudo apt install -y enscript
                        ;;
                    "ps2pdf")
                        sudo apt update && sudo apt install -y ghostscript
                        ;;
                    "git")
                        sudo apt update && sudo apt install -y git
                        ;;
                    *)
                        sudo apt update && sudo apt install -y "$tool"
                        ;;
                esac
            done
            echo -e "\n\033[1;32mAll required tools attempted for installation. Please re-run the script.\033[0m"
            exit 0
        else
            echo -e "\nPlease install the missing tools before running the script."
            exit 1
        fi
    fi
}

wizard() {
    echo -e "\n\033[1;36mWelcome to Domain Mapper Wizard!\033[0m"
    echo "Let's set up your scan. You can type 'help' at any step."
    read -rp "1. Enter the target network range (e.g., 192.168.1.0/24): " NETWORK_RANGE
    [[ "$NETWORK_RANGE" == "help" ]] && help_menu && exit 0
    read -rp "2. Enter the Domain name (e.g., mydomain.local): " DOMAIN
    [[ "$DOMAIN" == "help" ]] && help_menu && exit 0
    read -rp "3. Enter the Active Directory username [or leave blank]: " AD_USER
    [[ "$AD_USER" == "help" ]] && help_menu && exit 0
    read -rsp "4. Enter the Active Directory password [or leave blank]: " AD_PASS
    echo
    [[ "$AD_PASS" == "help" ]] && help_menu && exit 0
    read -rp "5. Enter path to password list [default: /usr/share/wordlists/rockyou.txt]: " PASS_LIST
    PASS_LIST=${PASS_LIST:-/usr/share/wordlists/rockyou.txt}
    [[ "$PASS_LIST" == "help" ]] && help_menu && exit 0
    echo "6. Select Scanning Level: "
    select SCAN_LEVEL in "None" "Basic" "Intermediate" "Advanced"; do
        [ -n "$SCAN_LEVEL" ] && break
    done
    echo "7. Select Enumeration Level: "
    select ENUM_LEVEL in "None" "Basic" "Intermediate" "Advanced"; do
        [ -n "$ENUM_LEVEL" ] && break
    done
    echo "8. Select Exploitation Level: "
    select EXPLOIT_LEVEL in "None" "Basic" "Intermediate" "Advanced"; do
        [ -n "$EXPLOIT_LEVEL" ] && break
    done
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    REPORT="DomainMapperReport_$TIMESTAMP"
    REPORT_TXT="$REPORT.txt"
    REPORT_PDF="$REPORT.pdf"
}

scan_basic() {
    progress "Scanning" "Running Nmap Basic (-Pn, TCP Top 1000)"
    nmap -Pn -T4 -oN scan_basic.txt "$NETWORK_RANGE"
    cat scan_basic.txt >> "$REPORT_TXT"
}
scan_intermediate() {
    progress "Scanning" "Running Nmap Intermediate (-p- All TCP ports)"
    nmap -Pn -T4 -p- -oN scan_intermediate.txt "$NETWORK_RANGE"
    cat scan_intermediate.txt >> "$REPORT_TXT"
}
scan_advanced() {
    progress "Scanning" "Running Nmap Advanced (Full TCP + UDP)"
    nmap -Pn -T4 -p- -sU --top-ports 100 -oN scan_advanced.txt "$NETWORK_RANGE"
    cat scan_advanced.txt >> "$REPORT_TXT"
}

enum_basic() {
    progress "Enumeration" "Service detection on open ports (-sV)"
    nmap -sV -oN enum_services.txt "$NETWORK_RANGE"
    cat enum_services.txt >> "$REPORT_TXT"
    progress "Enumeration" "Identifying Domain Controller and DHCP"
    nmap -p 53,67,88,135,139,389,445,636,3268,3269,3389 --open -oN dc_dhcp.txt "$NETWORK_RANGE"
    cat dc_dhcp.txt >> "$REPORT_TXT"
}
enum_intermediate() {
    progress "Enumeration" "Enumerating key services: FTP, SSH, SMB, WinRM, LDAP, RDP"
    nmap -p 21,22,445,3389,5985,389 --open -oN services_enum.txt "$NETWORK_RANGE"
    cat services_enum.txt >> "$REPORT_TXT"
    progress "Enumeration" "Enumerating shares and using NSE scripts"
    if [[ -n "$AD_USER" && -n "$AD_PASS" ]]; then
        enum4linux -u "$AD_USER" -p "$AD_PASS" "$NETWORK_RANGE" | tee enum4linux_enum.txt >> "$REPORT_TXT"
        nmap --script=smb-enum-shares.nse,smb-enum-users.nse,smb-os-discovery.nse \
          --script-args smbuser="$AD_USER",smbpass="$AD_PASS" -p445 "$NETWORK_RANGE" -oN nse_enum.txt
    else
        enum4linux -a "$NETWORK_RANGE" | tee enum4linux_enum.txt >> "$REPORT_TXT"
        nmap --script=smb-enum-shares.nse,smb-enum-users.nse,smb-os-discovery.nse -p445 "$NETWORK_RANGE" -oN nse_enum.txt
    fi
    cat nse_enum.txt >> "$REPORT_TXT"
}
enum_advanced() {
    # No output, nothing written to report (acts as a stub)
    :
}

exploit_basic() {
    progress "Exploitation" "Running NSE vuln scan (safe)"
    nmap --script vuln -oN exploit_nse.txt "$NETWORK_RANGE"
    cat exploit_nse.txt >> "$REPORT_TXT"
}

exploit_intermediate() {
    progress "Exploitation" "Domain-wide password spraying (Hydra)"
    if [[ -f enum4linux_enum.txt ]]; then
        > hydra_pspray.txt
        USER_COUNT=0
        for user in $(cut -d: -f1 enum4linux_enum.txt 2>/dev/null | grep -E "^[a-zA-Z0-9._-]+$" | sort -u | head -20); do
            hydra -L <(echo "$user") -P "$PASS_LIST" "$DOMAIN" smb -V | tee -a hydra_pspray.txt
            USER_COUNT=$((USER_COUNT+1))
        done
        if [[ -s hydra_pspray.txt && $USER_COUNT -gt 0 ]]; then
            cat hydra_pspray.txt >> "$REPORT_TXT"
        else
            echo "[*] No results from Hydra password spraying or no users found." | tee -a "$REPORT_TXT"
        fi
        rm -f hydra_pspray.txt
    else
        echo "No enum4linux_enum.txt found. Skipping password spraying." | tee -a "$REPORT_TXT"
    fi
}
exploit_advanced() {
    # No output, nothing written to report (acts as a stub)
    :
}

report_to_pdf() {
    progress "Reporting" "Generating PDF report"
    if command -v enscript >/dev/null 2>&1 && command -v ps2pdf >/dev/null 2>&1; then
        enscript -B -p "$REPORT.ps" "$REPORT_TXT"
        ps2pdf "$REPORT.ps" "$REPORT_PDF"
        rm "$REPORT.ps"
        echo -e "\nPDF report saved as $REPORT_PDF"
    else
        echo -e "\n\033[1;31mCould not find enscript and ps2pdf. PDF export not supported.\033[0m"
        echo "Please install 'enscript' and 'ghostscript' for PDF export."
    fi
}

main() {
    banner
    check_tools
    while true; do
        echo -e "\nType 'help' to show help menu, or press Enter to start."
        read -rp ">> " start_input
        [[ "$start_input" == "help" ]] && help_menu && continue
        break
    done
    wizard
    echo -e "\n\033[1;33mStarting Operations...\033[0m"
    case "$SCAN_LEVEL" in
        "Basic") scan_basic ;;
        "Intermediate") scan_basic; scan_intermediate ;;
        "Advanced") scan_basic; scan_intermediate; scan_advanced ;;
        *) echo "Skipping Scanning..." ;;
    esac
    case "$ENUM_LEVEL" in
        "Basic") enum_basic ;;
        "Intermediate") enum_basic; enum_intermediate ;;
        "Advanced") enum_basic; enum_intermediate; enum_advanced ;;
        *) echo "Skipping Enumeration..." ;;
    esac
    case "$EXPLOIT_LEVEL" in
        "Basic") exploit_basic ;;
        "Intermediate") exploit_basic; exploit_intermediate ;;
        "Advanced") exploit_basic; exploit_intermediate; exploit_advanced ;;
        *) echo "Skipping Exploitation..." ;;
    esac
    report_to_pdf
    echo -e "\n\033[1;32mOperation completed. Output is saved in $REPORT_PDF\033[0m"
    echo "Thank you for using Domain Mapper!"
    read -n1 -r -p "Press any key to close..."
    echo
}

main "$@"
