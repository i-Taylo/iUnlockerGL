#!/data/adb/iunlocker/bin/bash

# THIS SCRIPT IS PROTECTED! 
# CHANGING ANYTHING HERE WILL BREAK THE SCRIPT SIGNATURE 

source "/data/adb/iunlocker/share/Scripts/utilities.sh" || { 
    echo "Error while sourcing utilities script"
    exit 1
}

# Exit codes for success and failure
NS_SUCCESS=0      # Standard success exit code
NS_FAILURE=192    # Custom failure code (non-standard)

# Script arguments
NSPRGM="$1"       # The first argument: binary to run
NSNAME="$2"       # The second argument: namespace name
NSLTINIT="$3"     # The third argument: initialization parameter

# [w:ext], [w:utils], etc. are custom tags/flags, w: stands for "with ( include )"
NSZH72L="/proc:/sys:/system[w:ext]:/vendor[w:utils]:/apex[w:*]"

# Paths/patterns to exclude from mounting
# For example, exclude magisk-related files, adb data, ksud, etc.
NSEXCLUDE="*magisk*:*data/adb*:*ksud*:apd:"

{
    # STEP 1: Test the $NSPRGM binary before running it
    # The --testenv option checks if the environment is correctly set for $NSPRGM.
    # The string "w:runfrom->Application($0:runner=['/data/adb/iunlocker/bin/bash'])"
    # specifies that the runner is this current bash script ($NSPRGM requires trusted source)
    if ! $NSPRGM --testenv="w:runfrom->Application($0:runner=['/data/adb/iunlocker/bin/bash'])"; then
        # If the test fails, exit with the failure code 192
        exit $NS_FAILURE
    fi

    # STEP 2: If the test passes, attempt to run $NSPRGM with the given arguments
    if ! $NSPRGM --args="-n:$NSNAME, -n:ltinitbase:$NSLTINIT, -n:mirrorCastAs[n:part_handler]->str(w:en_regex($NSZH72L))" \
                 --setEnv="Mirroring::getEnv()?null" \
                 --dontmount="w:en_regex($NSEXCLUDE)"; then
        # STEP 3: If the above fails, flush and exit with the failure code
        # Only flush if $NSPRGM returned a non-zero exit code
        $NSPRGM --flush="w:exit_code->int($NS_FAILURE)"
    fi
}