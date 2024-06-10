#!/bin/bash

#Use at your own risk

# Directory containing the PCAP files 
#ex.: /Users/me/Documents/handshakes
PCAP_DIR="<insert PCAP folder here>"

# Output file for the combined PCAP, feel free to change name
COMBINED_PCAP="combined.pcap"

# Output file for the converted .hc22000 format, feel free to change name
COMBINED_HC22000="combined.hc22000"

# Directories containing the wordlists
# ex. ~/tools/SecLists/Passwords/WiFi-WPA
WORDLIST_DIRS=(
  <insert all possible wordlist directories here, one directory per line>
)

# Function to check if a file is valid (e.g., non-empty and readable)
is_valid_file() {
  local file=$1
  [[ -f "$file" && -r "$file" && -s "$file" ]]
}

# Check if there are any PCAP files in the directory
if [ "$(ls -1 "$PCAP_DIR"/*.pcap 2>/dev/null | wc -l)" -eq 0 ]; then
  echo "No PCAP files found in $PCAP_DIR."
  exit 1
fi

# Merge all PCAP files into one
echo "Merging all PCAP files into $COMBINED_PCAP..."
mergecap -w "$COMBINED_PCAP" "$PCAP_DIR"/*.pcap

# Check if merging was successful
if [[ -f "$COMBINED_PCAP" ]]; then
  # Convert the combined PCAP to .hc22000 format
  echo "Converting $COMBINED_PCAP to $COMBINED_HC22000..."
  hcxpcapngtool -o "$COMBINED_HC22000" "$COMBINED_PCAP"
  
  # Check if conversion was successful
  if [[ -f "$COMBINED_HC22000" ]]; then
    # Loop through each wordlist directory
    for WORDLIST_DIR in "${WORDLIST_DIRS[@]}"; do
      # Loop through each wordlist file in the directory
      for wordlist in "$WORDLIST_DIR"/*.txt; do
        if is_valid_file "$wordlist"; then
          echo "Running Hashcat on $COMBINED_HC22000 with $wordlist..."
          hashcat -m 22000 -a 0 "$COMBINED_HC22000" "$wordlist"
        else
          echo "Skipping invalid or empty file: $wordlist"
        fi
      done
    done
  else
    echo "Failed to convert $COMBINED_PCAP"
  fi
else
  echo "Failed to merge PCAP files."
fi

# Check for cracked passwords
echo "Checking for cracked passwords..."
if [[ -f ~/.hashcat/hashcat.potfile ]]; then
  cracked_passwords=$(awk -F: '{print $NF}' ~/.hashcat/hashcat.potfile)
  if [[ -n "$cracked_passwords" ]]; then
    echo "Cracked passwords found:"
    echo "$cracked_passwords"
  else
    echo "No cracked passwords found."
  fi
else
  echo "Hashcat potfile not found."
fi

echo "All operations completed."
