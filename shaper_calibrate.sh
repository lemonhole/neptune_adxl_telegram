#!/bin/bash
PRINTER_DATA="$HOME/printer_data"
OUTPUT_FOLDER="$PRINTER_DATA/config/adxl_results"
BOT_FOLDER="$OUTPUT_FOLDER/bot"
KLIPPER_SCRIPTS_LOCATION="$HOME/klipper/scripts"
RESONANCE_CSV_LOCATION="/tmp"

mkdir -p "$BOT_FOLDER"
cd "$RESONANCE_CSV_LOCATION" || exit

shopt -s nullglob
set -- resonances*.csv

if [ "$#" -gt 0 ]; then
    for each_file in resonances*.csv; do
        STATIC_NAME="${each_file:0:12}.png"
        HISTORY_NAME="$(echo "${each_file%.csv}" | cut -d'_' -f1,2,6,7 | sed 's/..$//').png"

        "$KLIPPER_SCRIPTS_LOCATION/calibrate_shaper.py" "$each_file" -o "$BOT_FOLDER/$STATIC_NAME"
        cp "$BOT_FOLDER/$STATIC_NAME" "$OUTPUT_FOLDER/$HISTORY_NAME"
        rm "$each_file"
    done
else
    echo "No CSV files found to process"
fi
