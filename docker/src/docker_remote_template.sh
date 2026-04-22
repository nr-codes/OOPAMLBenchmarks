#!/usr/bin/env bash

source ../.bashrc

# Loop through all AMPL/python scripts in the current directory
TS=$(date +"%Y%m%d_%H%M%S")
for file in *.SCRIPT; do
  # Skip if no .SCRIPT files exist
  [ -e "$file" ] || continue

  # Extract base name without extension
  base="${file%.SCRIPT}"

  # Run the AMPL/python file and redirect output
  echo "Processing $file → ${base}.txt"
  RUN "$file" > "${base}_SCRIPT_${TS}.txt" 2>&1
  mv "${base}.OUT" "${base}_${TS}.OUT"
done

# tar all .txt files and the mat_files directory
echo "Creating archive."
cd ../
mv LIB LIB_out
tar -czvf LIB_out.tgz LIB_out
