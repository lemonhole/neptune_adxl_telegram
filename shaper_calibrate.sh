#!/bin/bash
OUTPUT_FOLDER="config/adxl_results"
PRINTER_DATA="$HOME/printer_data"
KLIPPER_SCRIPTS_LOCATION="$HOME/klipper/scripts"
RESONANCE_CSV_LOCATION="/tmp"

mkdir -p "$PRINTER_DATA/$OUTPUT_FOLDER"
cd "$RESONANCE_CSV_LOCATION" || exit

shopt -s nullglob
set -- resonances*.csv

if [ "$#" -gt 0 ]; then
    for each_file in resonances*.csv; do
        HISTORY_NAME="$(echo "${each_file%.csv}" | cut -d'_' -f1,2,6,7).png"
        STATIC_NAME="${each_file:0:12}.png"

        "$KLIPPER_SCRIPTS_LOCATION/calibrate_shaper.py" "$each_file" -o "$PRINTER_DATA/$OUTPUT_FOLDER/$STATIC_NAME"
        cp "$PRINTER_DATA/$OUTPUT_FOLDER/$STATIC_NAME" "$PRINTER_DATA/$OUTPUT_FOLDER/$HISTORY_NAME"
        rm "$each_file"
    done
else
    echo "No CSV files found in $RESONANCE_CSV_LOCATION"
fi
