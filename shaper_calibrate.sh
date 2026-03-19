#! /bin/bash
OUTPUT_FOLDER=config/adxl_results
PRINTER_DATA=$HOME/printer_data
KLIPPER_SCRIPTS_LOCATION=~/klipper/scripts
RESONANCE_CSV_LOCATION=tmp
if [ ! -d  /$PRINTER_DATA/$OUTPUT_FOLDER/ ] #Check if we have an output folder
then
    mkdir /$PRINTER_DATA/$OUTPUT_FOLDER/
fi

cd /$RESONANCE_CSV_LOCATION/

shopt -s nullglob
set -- resonances*.csv

if [ "$#" -gt 0 ]
then
    for each_file in resonances*.csv
    do
        CLEAN_NAME=$(echo "$each_file" | cut -d'_' -f1,2,6,7)
        HISTORY_NAME="${CLEAN_NAME%.csv}.png"
        STATIC_NAME="resonances_x.png"

        $KLIPPER_SCRIPTS_LOCATION/calibrate_shaper.py "$each_file" -o "$PRINTER_DATA/$OUTPUT_FOLDER/$STATIC_NAME"
        cp "$PRINTER_DATA/$OUTPUT_FOLDER/$STATIC_NAME" "$PRINTER_DATA/$OUTPUT_FOLDER/$HISTORY_NAME"
        rm "$RESONANCE_CSV_LOCATION/$each_file"
    done
else
    echo "Something went wrong, no csv found to process"
fi
