
# Domain-Mapper

Automated Bash script for Active Directory and network domain reconnaissance, enumeration, and reporting.  
Built for penetration testers, SOC analysts, blue teamers, and anyone who wants to map and audit domain environments in one click.

---

## Features

- **Automated Nmap scanning** (multiple levels: Top 1000, all TCP, TCP+UDP)
- **Service & share enumeration** (including DC/DHCP/LDAP/SMB info)
- **Password spraying (Hydra)**
- **NSE vulnerability scans**
- **Interactive wizard (step-by-step config)**
- **PDF report generation** (automatic, for easy submission/audit)
- **Kali Linux native; checks dependencies and guides user**
- **Colorful CLI UI and progress banners**

---

## How It Works

1. **Setup:**  
   Launch the script and follow the wizard.  
   Select scan/enumeration/exploitation levels, provide optional AD credentials and password list.
2. **Scan:**  
   Nmap scans the network (from basic to advanced).
3. **Enumerate:**  
   Discovers open services, key domain roles, and shares.
4. **Exploit:**  
   Runs safe vulnerability scans and attempts password spraying with Hydra.
5. **Report:**  
   All findings are saved to TXT and converted to PDF for easy review.

---

## Usage

```bash
chmod +x Domain\ Mapper.sh
sudo ./Domain\ Mapper.sh
```

**You must run as root for full functionality.**

### **Typical Flow**
- Enter the network range (e.g., `192.168.1.0/24`)
- Enter the domain name (optional)
- Enter AD credentials (optional, for deeper enum)
- Select password list (e.g., `/usr/share/wordlists/rockyou.txt`)
- Choose scan/enum/exploit levels (`Basic`, `Intermediate`, `Advanced`)
- Wait for results; report will be generated in PDF (and TXT)

---

## Requirements

- **Kali Linux**
- `nmap`, `hydra`, `enum4linux`, `rpcclient`, `sipcalc`, `enscript`, `ghostscript` (ps2pdf), `git`
- Internet access for installing missing tools (script will prompt if needed)

---

## Example Output

> PDF report will look like:
> - Open ports/services (with version info)
> - List of detected DCs/DHCP/LDAP/SMB shares
> - Password spraying results (if AD users found)
> - Vulnerabilities found (NSE scripts)
> - All commands and steps are logged for full transparency

**No sensitive data is stored or shared. IPs/domains/credentials provided at runtime are not logged in this repository or README.**

---

## Author

Elior Salimi  
[GitHub profile](https://github.com/elior2000)

---

## License

This project is released under the MIT License.  

---

## Disclaimer

This script is intended for educational, training, and authorized security testing purposes only.  
**Do not use against systems without proper authorization.**

---
