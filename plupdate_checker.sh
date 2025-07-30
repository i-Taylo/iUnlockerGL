#!/data/adb/iunlocker/bin/bash

source "/data/adb/iunlocker/share/Scripts/utilities.sh" || { 
    echo "Error while sourcing utilities script"
    exit 1
}

PLUGIN_NAME=""
FIELD=""
PLUGINS_JURL="https://raw.githubusercontent.com/i-Taylo/iUnlockerGL/refs/heads/main/biscuits/plugins.json"

export MEMORY_SIGNAL_MAGIC='0xE5FE'

function spr() {
	local message="$1"
	local NO_IGNORE_ON_PRINT="004"
	# silent | echo -e "[[$MEMORY_SIGNAL_MAGIC$NO_IGNORE_ON_PRINT]](\"$message\")"
}

function raise_error() {
	local reason="$1"
	local EXIT_FAILURE=1
	# "Contain" the error message into the memory magic
	echo -e "[[$MEMORY_SIGNAL_MAGIC]](\"$reason\")"
	return $EXIT_FAILURE
}

for arg in "$@"; do
  case $arg in
    -plugin_name=*)
      PLUGIN_NAME="${arg#*=}"
      ;;
    -getVersion)
      FIELD="version"
      ;;
    -getVersionCode)
      FIELD="versionCode"
      ;;
    -getExecUrl)
      FIELD="executableUrl"
      ;;
    -getChangelog)
      FIELD="changelog"
      ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

if [[ -z "$PLUGIN_NAME" || -z "$FIELD" ]]; then
  echo "Usage: bash $0 -plugin_name=\"<plugin>\" -getVersion | -getVersionCode | -getExecUrl | -getChangelog"
  exit 1
fi

JSON_FILE="$TEMPDIR/plugins.json"

if ! download "$JSON_FILE" "$PLUGINS_JURL"; then
    raise_error "Failed to download plugins.json"
    exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: $JSON_FILE not found!"
  exit 1
fi

# Use jq to extract the field value from the plugin
VALUE=$(jq -r ".[\"$PLUGIN_NAME\"][\"$FIELD\"] // empty" "$JSON_FILE")

if [[ -z "$VALUE" ]]; then
  echo "Plugin '$PLUGIN_NAME' or field '$FIELD' not found"
  exit 1
fi

echo "$VALUE"