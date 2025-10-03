#!/usr/bin/env bash
# nikto_from_amass_v2.sh

set -euo pipefail

INPUT_PATH="${1:-/home/amirhosein/Desktop/amass_results/unfxco.com/subs_.txt}"
OUTDIR="${HOME}/nikto_results/unfxco.com/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
SUMMARY_FILE="${OUTDIR}/summary.log"

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}[*] Input file: $INPUT_PATH${RESET}"
echo -e "${BLUE}[*] Results directory: $OUTDIR${RESET}"
echo "[#] Nikto scan summary" > "$SUMMARY_FILE"
echo "[#] Date: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Dependency check
command -v nikto >/dev/null 2>&1 || { echo -e "${RED}[!] nikto not found. Install it.${RESET}"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo -e "${RED}[!] curl not found. Install it.${RESET}"; exit 1; }

# Start reading file
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue

  host=$(echo "$line" | awk '{print $1}' | tr -d $'\r\t\n ')
  [[ -z "$host" ]] && continue

  echo -e "${YELLOW}-----${RESET}"
  echo -e "${GREEN}[*] Scanning: $host${RESET}"

  ts=$(date +%Y%m%d_%H%M%S)
  safe_host=$(echo "$host" | sed 's/[^a-zA-Z0-9._-]/_/g')
  outfile="${OUTDIR}/${safe_host}_${ts}.txt"

  if curl -s --head --max-time 5 "https://$host" >/dev/null 2>&1; then
    url="https://$host"
  else
    url="http://$host"
  fi

  echo -e "${BLUE}[*] Using URL: $url${RESET}"
  echo "[URL] $url" > "$outfile"
  echo "[Time] $(date)" >> "$outfile"
  echo "[Host] $host" >> "$outfile"
  echo "" >> "$outfile"

  if nikto -h "$url" >> "$outfile" 2>&1; then
    echo -e "${GREEN}[+] Nikto scan successful${RESET}"
    echo "[+] $host ($url) -> $(basename "$outfile")" >> "$SUMMARY_FILE"
  else
    echo -e "${RED}[-] Nikto scan failed${RESET}"
    echo "[-] $host ($url) [FAILED] -> $(basename "$outfile")" >> "$SUMMARY_FILE"
  fi

  echo -e "${BLUE}[*] Output: $outfile${RESET}"
  sleep 1

done < "$INPUT_PATH"

echo -e "${GREEN}[*] Done. Summary saved to:${RESET} ${SUMMARY_FILE}"
