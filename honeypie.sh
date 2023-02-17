#!/bin/bash

# User interface for Nmap Vulnerability Assessment
# Allows for easy use of Nmap with vulnerability database cross-referencing

# Get target IP address or hostname
read -r -p "Enter the target IP address or hostname: " target

# Get port(s) to scan
read -r -p "Enter the port(s) to scan (e.g. 80,443,100-200): " ports

# Get output file name
read -r -p "Enter the name of the output file: " output_file_name

# Get NSE script to run
echo "Select an NSE script to run:"
select script in $(ls /usr/share/nmap/scripts/)
do
  # Get additional options
  read -r -p "Enter any additional options (e.g. --script-args): " options
  
  # Run Nmap with the selected NSE script and additional options
  nmap -sC -sV -p "$ports" --script "$script" -oN "$output_file_name" "$target"
  
  # Cross-reference results with Searchsploit database
  while read -r line
  do
    vuln_name=$(echo "$line" | cut -d' ' -f 2-)
    vuln_id=$(echo "$line" | cut -d' ' -f 1)
    if searchsploit -w "$vuln_name" >/dev/null 2>&1; then
      echo "Vulnerability ID $vuln_id - $vuln_name: Vulnerable" >> "$output_file_name"
    else
      echo "Vulnerability ID $vuln_id - $vuln_name: Not vulnerable" >> "$output_file_name"
    fi
  done < <(grep -Eo '\[[0-9]+\] .*' "$output_file_name")
  
  break
done

# Generate HTML report from output file
html_file="${output_file_name%.*}.html"
echo "Generating HTML report: $html_file"
nmap-parse-output -x "$output_file_name" -f "$html_file"

echo "Finished vulnerability assessment. Results are in $output_file_name and ${output_file_name%.*}.html."
