#!/bin/bash

RB_PAGE=0
RB_PAGE_SIZE=100

# Function to get bearer token
get_bearer_token() {
  RB_RESPONSE=$(curl -s 'https://api.redbacktech.com/Api/v2/Auth/token' \
    -H 'Authorization: Basic '"$(echo -n $RB_CLIENT_ID:$RB_CLIENT_SECRET | base64)" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-raw 'grant_type=client_credentials' \
    --compressed)

  echo "$RB_RESPONSE"
}

# Function to extract bearer token from response
extract_bearer_token() {
  local bearer_token=$(echo "$1" | jq -r '.access_token')
  echo "$bearer_token"
}

# Function to get dynamic data for a site
get_dynamic_data() {
  local bearer_token=$1
  local site_id=$2

  RB_RESPONSE=$(curl -s "https://api.redbacktech.com/Api/v2/EnergyData/$site_id/Dynamic" \
    -H "Authorization: Bearer $bearer_token" \
    --compressed)

  echo "$RB_RESPONSE"
}

# Function to upload data to PVOutput API
upload_to_pvoutput() {
  local api_key=$1
  local system_id=$2
  local dynamic_data=$3

  echo "PVOutput Data: $dynamic_data"

  # Extract the required fields from the dynamic data
  local utc_timestamp=$(echo "$dynamic_data" | jq -r '.Data.TimestampUtc')
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


  local power_generation=$(echo "$dynamic_data" | jq -r '.Data.PvPowerInstantaneouskW * 1000')
  local energy_generation=$(echo "$dynamic_data" | jq -r '.Data.PvPowerInstantaneouskW * 1000')
  echo "Power Generation: $power_generation"
  PvAllTimeEnergykWh
  local pvalltime_energy=$(echo "$dynamic_data" | jq -r '.Data.PvAllTimeEnergykWh * 1000')
  local export_energy=$(echo "$dynamic_data" | jq -r '.Data.ExportAllTimeEnergykWh * 1000')
  local import_energy=$(echo "$dynamic_data" | jq -r '.Data.ImportAllTimeEnergykWh * 1000')

  local power_consumption=$((pvalltime_energy - export_energy + import_energy))

  echo "Power Consumption: $power_consumption"
#  local power_consumption_A=$(echo "$dynamic_data" | jq -r '.Data.Phases[] | select(.Id == "A") | .ActiveImportedPowerInstantaneouskW')
#  echo "Power Consumption Phase A: $power_consumption_A"
#
#  local power_consumption_B=$(echo "$dynamic_data" | jq -r '.Data.Phases[] | select(.Id == "B") | .ActiveImportedPowerInstantaneouskW')
#  echo "Power Consumption Phase B: $power_consumption_B"
#
#  local power_consumption_C=$(echo "$dynamic_data" | jq -r '.Data.Phases[] | select(.Id == "C") | .ActiveImportedPowerInstantaneouskW')
#  echo "Power Consumption Phase C: $power_consumption_C"

  local curl_command="curl -s 'https://pvoutput.org/service/r2/addstatus.jsp' \
    -H 'X-Pvoutput-Apikey: $api_key' \
    -H 'X-Pvoutput-SystemId: $system_id' \
    -d 'd=$local_date' \
    -d 't=$local_time' \
    -d 'v2=$power_generation' \
    -d 'v4=$power_consumption' \
    --compressed"

  echo "Curl Command: $curl_command"

  PV_RESPONSE=$(eval "$curl_command")

  echo "$PV_RESPONSE"
}

# Extract relevant data from


# Get bearer token
RB_RESPONSE=$(get_bearer_token)
echo "Response: $RB_RESPONSE"

# Extract bearer token
BEARER_TOKEN=$(extract_bearer_token "$RB_RESPONSE")
echo "Bearer Token: $BEARER_TOKEN"

# Get site IDs
SITE_IDS=$(curl -s 'https://api.redbacktech.com/Api/v2/EnergyData?page=0&pageSize=100' \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  --compressed)

echo "Site IDS: $SITE_IDS"

# Function to get bearer token
get_bearer_token() {
  RB_RESPONSE=$(curl -s 'https://api.redbacktech.com/Api/v2/Auth/token' \
    -H 'Authorization: Basic '"$(echo -n $RB_CLIENT_ID:$RB_CLIENT_SECRET | base64)" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-raw 'grant_type=client_credentials' \
    --compressed)

  echo "$RB_RESPONSE"
}

# Function to extract bearer token from response
extract_bearer_token() {
  local bearer_token=$(echo "$1" | jq -r '.access_token')
  echo "$bearer_token"
}

# Function to get dynamic data for a site
get_dynamic_data() {
  local bearer_token=$1
  local site_id=$2

  RB_RESPONSE=$(curl -s "https://api.redbacktech.com/Api/v2/EnergyData/$site_id/Dynamic?metadata=true" \
    -H "Authorization: Bearer $bearer_token" \
    --compressed)

  echo "$RB_RESPONSE"
}

# Get bearer token
RB_RESPONSE=$(get_bearer_token)
echo "Response: $RB_RESPONSE"

# Extract bearer token
BEARER_TOKEN=$(extract_bearer_token "$RB_RESPONSE")
echo "Bearer Token: $BEARER_TOKEN"

# Get site IDs
SITE_IDS=$(curl -s 'https://api.redbacktech.com/Api/v2/EnergyData?page=0&pageSize=100' \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  --compressed)

echo "Site IDS: $SITE_IDS"

# Loop through each site ID and fetch dynamic data
for SITE_ID in $(echo "$SITE_IDS" | jq -r '.Data[]'); do
  echo "Site ID: $SITE_ID"

  # Get dynamic data for site
  DYNAMIC_DATA=$(get_dynamic_data "$BEARER_TOKEN" "$SITE_ID")
  echo "Dynamic Data: $DYNAMIC_DATA"


  # Upload data to PVOutput API
  PV_RESPONSE=$(upload_to_pvoutput "$PVOUTPUT_API_KEY" "$PVOUTPUT_SYSTEM_ID" "$DYNAMIC_DATA")
  echo "PVOutput Response: $PV_RESPONSE"

  echo "======================"
done


