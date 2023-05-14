#!/bin/bash


# Check if the system is macOS
if [[ $(uname) == "Darwin" ]]; then
  date_cmd="gdate"
else
  date_cmd="date"
fi

# Local time zone
local_timezone=$($date_cmd +%z)

echo "Local Time Zone: $local_timezone"

# Convert UTC timestamp to local date and time
local_datetime=$($date_cmd -d "$utc_timestamp" +"%Y%m%d %H:%M")

local_date=${local_datetime% *}
local_time=${local_datetime#* }

echo "UTC Timestamp: $utc_timestamp"
echo "Local Date: $local_date"
echo "Local Time: $local_time"

