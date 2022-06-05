#!/usr/bin/env bash
# PixelBlaster build helper script

# red = errors, cyan = warnings, green = confirmations, blue = informational
# plain for generic text, bold for titles, reset flag at each end of line
# plain blue should not be used for readability reasons - use plain cyan instead
CLR_RST=$(tput sgr0)                        ## reset flag
CLR_RED=$CLR_RST$(tput setaf 1)             #  red, plain
CLR_GRN=$CLR_RST$(tput setaf 2)             #  green, plain
CLR_BLU=$CLR_RST$(tput setaf 4)             #  blue, plain
CLR_CYA=$CLR_RST$(tput setaf 6)             #  cyan, plain
CLR_BLD=$(tput bold)                        ## bold flag
CLR_BLD_RED=$CLR_RST$CLR_BLD$(tput setaf 1) #  red, bold
CLR_BLD_GRN=$CLR_RST$CLR_BLD$(tput setaf 2) #  green, bold
CLR_BLD_BLU=$CLR_RST$CLR_BLD$(tput setaf 4) #  blue, bold
CLR_BLD_CYA=$CLR_RST$CLR_BLD$(tput setaf 6) #  cyan, bold

# Set defaults
BUILD_TYPE="userdebug"

function checkExit () {
    if [ $? -ne 0 ]; then
        EXIT_CODE=$?
        echo "${CLR_BLD_RED}Build failed!${CLR_RST}"
        echo -e ""
        exit $EXIT_CODE
    fi
}

# Output usage help
function showHelpAndExit {
        echo -e "${CLR_BLD_BLU}Usage: $0 <device> [options]${CLR_RST}"
        echo -e ""
        echo -e "${CLR_BLD_BLU}Options:${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -h, --help            Display this help message${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -c, --clean           Wipe the tree before building${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -i, --installclean    Dirty build - Use 'installclean'${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -r, --repo-sync       Sync before building${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -v, --variant         Build Variant - Can be Gapps or Vanilla${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -t, --build-type      Build type - Can be user, userdebug or eng${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -j, --jobs            Specify jobs/threads to use${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -m, --module          Build a specific module${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -o, --official        Build official build${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -u, --upload          Automatically upload release build and push OTA update${CLR_RST}"
        exit 1
}

# Setup getopt.
long_opts="help,clean,installclean,repo-sync,variant:,build-type:,jobs:,module:,official,upload"
getopt_cmd=$(getopt -o hcirv:t:j:m:ou --long "$long_opts" \
            -n $(basename $0) -- "$@") || \
            { echo -e "${CLR_BLD_RED}\nError: Getopt failed. Extra args\n${CLR_RST}"; showHelpAndExit; exit 1;}

eval set -- "$getopt_cmd"

while true; do
    case "$1" in
        -h|--help|h|help) showHelpAndExit;;
        -c|--clean|c|clean) FLAG_CLEAN_BUILD=y;;
        -i|--installclean|i|installclean) FLAG_INSTALLCLEAN_BUILD=y;;
        -r|--repo-sync|r|repo-sync) FLAG_SYNC=y;;
        -v|--variant|v|variant) BUILD_GAPPS="$2"; shift;;
        -t|--build-type|t|build-type) BUILD_TYPE="$2"; shift;;
        -j|--jobs|j|jobs) JOBS="$2"; shift;;
        -m|--module|m|module) MODULE="$2"; shift;;
        -o|--official|o|official) OFFICIAL=y;;
        -u|--upload|u|upload) UPLOAD=y;;
        --) shift; break;;
    esac
    shift
done

# Mandatory argument
if [ $# -eq 0 ]; then
    echo -e "${CLR_BLD_RED}Error: No device specified${CLR_RST}"
    showHelpAndExit
fi
export DEVICE="$1"; shift

# Make sure we are running on 64-bit before carrying on with anything
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
if [ "$ARCH" != "64" ]; then
        echo -e "${CLR_BLD_RED}error: unsupported arch (expected: 64, found: $ARCH)${CLR_RST}"
        exit 1
fi

# Set up paths
cd $(dirname $0)
DIR_ROOT=$(pwd)

# Make sure everything looks sane so far
if [ ! -d "$DIR_ROOT/vendor/aosp" ]; then
        echo -e "${CLR_BLD_RED}error: insane root directory ($DIR_ROOT)${CLR_RST}"
        exit 1
fi

# Setup Build variant if specified
if [ $BUILD_GAPPS ]; then
    BUILD_GAPPS=`echo $BUILD_GAPPS |  tr "[:upper:]" "[:lower:]"`
    if [ "${BUILD_GAPPS}" = "gapps" ]; then
        export BUILD_GAPPS=Gapps
    elif [ "${BUILD_GAPPS}" = "vanilla" ]; then
        export BUILD_GAPPS=Vanilla
    else
        echo -e "${CLR_BLD_RED} Unknown Build variant - use vanilla or gapps${CLR_RST}"
        exit 1
    fi
fi

# Setup Official Build if specified
if [ $OFFICIAL ]; then
    OFFICIAL=`echo $OFFICIAL |  tr "[:upper:]" "[:lower:]"`
    if [ "${OFFICIAL}" = "y" ]; then
        export BLASTER_BUILD_TYPE=OFFICIAL
    else
        export BLASTER_BUILD_TYPE=UNOFFICIAL
        exit 1
    fi
fi

# Initializationizing!
echo -e "${CLR_BLD_BLU}Setting up the environment${CLR_RST}"
echo -e ""
. build/envsetup.sh
echo -e ""

# Use the thread count specified by user
CMD=""
if [ $JOBS ]; then
  CMD+="-j$JOBS"
fi

# Pick the default thread count (allow overrides from the environment)
if [ -z "$JOBS" ]; then
        if [ "$(uname -s)" = 'Darwin' ]; then
                JOBS=$(sysctl -n machdep.cpu.core_count)
        else
                JOBS=$(cat /proc/cpuinfo | grep '^processor' | wc -l)
        fi
fi

# Grab the build version
BLASTER_DISPLAY_VERSION="$(cat $DIR_ROOT/vendor/aosp/config/branding.mk | grep 'BLASTER_VERSION := *' | sed 's/.*= //')"

# Prep for a clean build, if requested so
if [ "$FLAG_CLEAN_BUILD" = 'y' ]; then
        echo -e "${CLR_BLD_BLU}Cleaning output files left from old builds${CLR_RST}"
        echo -e ""
        m clobber "$CMD"
fi

# Prep for a installclean build, if requested so
if [ "$FLAG_INSTALLCLEAN_BUILD" = 'y' ]; then
        echo -e "${CLR_BLD_BLU}Cleaning compiled image files left from old builds${CLR_RST}"
        echo -e ""
        m installclean "$CMD"
fi

# Sync up, if asked to
if [ "$FLAG_SYNC" = 'y' ]; then
        echo -e "${CLR_BLD_BLU}Downloading the latest source files${CLR_RST}"
        echo -e ""
        repo sync -j"$JOBS" -c --no-clone-bundle --current-branch --no-tags
fi

# Check the starting time (of the real build process)
TIME_START=$(date +%s.%N)

# Friendly logging to tell the user everything is working fine is always nice
echo -e "${CLR_BLD_GRN}Building PixelBlaster $BLASTER_DISPLAY_VERSION for $DEVICE${CLR_RST}"
echo -e "${CLR_GRN}Start time: $(date)${CLR_RST}"
echo -e ""

# Lunch-time!
echo -e "${CLR_BLD_BLU}Lunching $DEVICE${CLR_RST} ${CLR_CYA}${CLR_RST}"
echo -e ""
lunch "aosp_$DEVICE-$BUILD_TYPE"
echo -e ""

# Build away!
echo -e "${CLR_BLD_BLU}Starting compilation${CLR_RST}"
echo -e ""

# If we aren't in Jenkins, use the engineering tag
if [ -z "${BUILD_NUMBER}" ]; then
    export FILE_NAME_TAG=eng.$USER
else
    export FILE_NAME_TAG=$BUILD_NUMBER
fi

# Build a specific module
if [ "${MODULE}" ]; then
    m $MODULE "$CMD"
    checkExit

fi

    # Make package for distribution
    make bacon "$CMD"
    export BUILD_ZIP=`cat blaster_zip`
if [ ! -z "$OFFICIAL" ]
then
if [ ! -z "$UPLOAD" ] 
then
        echo -e "${CLR_BLD_GRN}Pushing OTA...${CLR_RST}"
        ./ota.sh
fi
fi

    rm blaster_zip

echo -e ""

# Check the finishing time
TIME_END=$(date +%s.%N)

# Log those times at the end as a fun fact of the day
echo -e "${CLR_BLD_GRN}Total time elapsed:${CLR_RST} ${CLR_GRN}$(echo "($TIME_END - $TIME_START) / 60" | bc) minutes ($(echo "$TIME_END - $TIME_START" | bc) seconds)${CLR_RST}"
echo -e ""

exit 0
