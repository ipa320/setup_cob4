#!/bin/sh
#
echo "Write variables"

nvram set time_zone="Europe/Berlin"

# Commit variables
echo "Save variables to nvram"
nvram commit
