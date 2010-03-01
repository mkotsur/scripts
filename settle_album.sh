#!/bin/bash
#Script to extract downloaded archives with music
#

# variable keeps steps to be done in case of fail (kinda transaction state)
declare -a steps

CONFIG_FILE_PATH="$HOME/.settle_album"

# Default settings
DEFAULT_TARGET_PATH="$HOME/Music"
DEFAULT_TEMPLATE="%b/%y - %a"
DEFAULT_TEMPLATE_WITHOUT_YEAR="%b/%a"
DEFAULT_DELETE_AFTER_UNPACK=1
DEFAULT_PROCESS_TAGS=1

# Stores action for performing in case of rollback
function addRevertStep {
    steps[${#steps[@]}]="$1"
}

# Proceed rollback
function doRevertSteps {
    cmd_count=${#steps[@]}

    message "Commands to revert "$cmd_count

    cmd_index=$cmd_count
    let "cmd_index = cmd_count - 1"
    while [ $cmd_index -ge 0 ]
        do
        cmd=${steps[$cmd_index]}
        message " ** Command $cmd_index of $cmd_count: " $cmd
                   

        if eval $cmd &> /dev/null
            then
                message "EXECUTED"
            else
                error "Could not execute reverting command..."
                error "You must do it manually"
        fi

        let "cmd_index = cmd_index - 1"

    done
}

function error {
    echo " (!) Error: "$1
}

function message {
    echo " -> Info: "$1
}

function debug {
    if [[ $verbose -eq 1 ]]; then echo " (>|<) "$1; fi
}

function success {
    if [[ $delete_after_unpack -eq 1 ]]
        then
            message "Deleting source archive."
            rm -f "$archive"
    fi
    message "SUCEEDED TO UNPACK ARCHIVE"
    exit 0
}

function fail  {
    error "FAILED TO UNPACK ARCHIVE"
    doRevertSteps
    exit $1
}

function printHelp {

    echo "Script for extracting music from archives..."
    echo " -- Options --"
    echo -e "   \033[1m-b\033[0m [required] Band name"
    echo -e "   \033[1m-a\033[0m [required] Album name"
    echo -e "   \033[1m-y\033[0m [optional] release Year"
    echo ""
    echo " -- Keys --"
    echo -e "   \033[1m-v\033[0m [optional] Verbose"
    echo ""
    echo " -- Settings --"
    echo -e "Could be defined in config file located at \033[1m~/.settle_album\033[0m"
    echo "Example given below."
    echo ''
    echo -e "   \033[1mtarget_path\033[0m : Path to the music collection. Default: \"$DEFAULT_TARGET_PATH\";"
    echo -e "   \033[1mtemplate\033[0m : Template of path inside \"target_path\" where unpacked files will be located if year specified. Default: \"$DEFAULT_TEMPLATE\";"
    echo -e "   \033[1mtemplate_without_year\033[0m : Template of path when year not specified. Default: \"$DEFAULT_TEMPLATE_WITHOUT_YEAR\";"
    echo -e "   \033[1mdelete_after_unpack\033[0m : Delete source archive after successful unpacking - 1 or 0. Default: \"$DEFAULT_DELETE_AFTER_UNPACK\"."
    echo -e "   \033[1mprocess_tags\033[0m : Convert tags into UTF-8 - 1 or 0. Default: \"$DEFAULT_DELETE_AFTER_UNPACK\"."
    echo ""
    echo " -- Usage --"
    echo -e "   \033[1m./settle_album.sh -b\033[0m \"Band name\" \033[1m-a\033[0m \"Album name\" \033[1m-y\033[0m YYYY \033[1m~/Downloads/music_archive.rar\033[0m"
    echo ""
    echo "Currently supported types: zip, rar, 7z. If there is no config file with another settings, files will be unpacked to $DEFAULT_TARGET_PATH/$DEFAULT_TEMPLATE/*."
    echo "Directory structure inside archive will be suppressed."
    echo ""
    echo " -- Config file example --"
    echo 'mkotsur@n-fox:~$ cat ~/.settle_album'
    echo ''
    echo '  target_path="/home/mkotsur/Music/"'
    echo '  template="%b/%y-%a"'
    echo '  template_without_year="%b/%a"'
    echo '  delete_after_unpack=0'
    echo '  process_tags=0'

    echo ''
    echo ' -- About --'
    echo 'Script provided as is.'
    echo 'Author: Mykhailo Kotsur. http://sotomajor.org.ua'
    echo 'You are welcome to suggest or contribute: http://github.com/mkotsur/scripts'
    exit 0

}

# Validates input
function validate {

    if [ ! -d "$target_path" ]; then error "Path \"$target_path\" does not exist"; error "Create it first or define another in config file"; fail 1; fi

    if [ "$5"  = "0" ]; then error "What to unpack?"; error "Last argument should be path to archive."; fail 1; fi

    if [ ! -f "$4" ]; then error "Archive $4 does not exists."; fail 1; fi

    if [[ ! "$4" =~ ^.*\.(zip|ZIP|rar|RAR|7z) ]]; then error "Unsupported type of archive."; fail 1; fi

    if [ "$1" == "" ]; then error "Band name missing."; fail 1; fi

    if [ "$2" == "" ]; then error "Album name missing."; fail 1; fi
}

# Creates dir by specified path
function createDir {

    debug "createDir param: $1"

    if [ -d "$1" ]
        then
            error "Directory \"$1\" already exists."
            fail 1
        else
            if mkdir -p "$1" &> /dev/null
                then
                    message "Created \"$1\""
                    addRevertStep "rm -rf \"$1\""
                else
                    error "Can not create \"$1\""
                    fail 1
            fi
    fi
}

# Define settings not specified in config file
function processSettings {

    if [[ ! $target_path ]]; then target_path="$HOME/Music"; debug "Setting default target_path"; fi

    if [[ ! $template ]]; then template=$DEFAULT_TEMPLATE; debug "Setting default template"; fi

    if [[ ! $template_without_year ]]
        then template_without_year=$DEFAULT_TEMPLATE_WITHOUT_YEAR
        debug "Setting default template_without_year"
    fi

    if [[ ! $delete_after_unpack ]]
        then delete_after_unpack=$DEFAULT_DELETE_AFTER_UNPACK
        debug "Setting default delete_after_unpack"
    fi

    if [[ ! $process_tags ]]
    	then process_tags=$DEFAULT_PROCESS_TAGS
	    debug "Setting default process_tags"
    fi

}

function dumpDebugSettings {
    debug " -- Options --"
    debug "Band:\"$band\""
    debug "Album:\"$album\""
    debug "Year:\"$year\""
    debug "Archive:\"$archive\""
    debug "Verbose: \"$verbose\""
    debug " -- Settings --"
    debug "Target path: \"$target_path\""
    debug "Template: \"$template\""
    debug "Template without year: \"$template_without_year\""
    debug "Delete after unpack: \"$delete_after_unpack\""
}

function getRelativeAlbumPath {
    local path

    if [[ ! $3 ]]
        then
            path="$template_without_year"
        else
            path=`echo "$template" | sed -e "s/%y/$3/"`
    fi

    path=`echo "$path" | sed -e "s/%b/$1/" | sed -e "s/%a/$2/"`

    echo $path
}

##################
#   Main logic   #
##################

if [[ $# -eq 0 ]]; then printHelp; fi;

while getopts "b:a:y:vh" optname
do
    case "$optname" in
        b)
            band=$OPTARG
            ;;
        a)
            album=$OPTARG
            ;;
        y)
            year=$OPTARG
            ;;
        v)
            verbose=1
            ;;
        h)
            printHelp
            ;;
        *)
            fail 1
    esac
done

shift $(($OPTIND - 1))

args=$#
archive=${!args}

# Load external settings if any
if [[ -f $CONFIG_FILE_PATH ]]
    then
        debug "Including external settings from \"$CONFIG_FILE_PATH\""
        . $CONFIG_FILE_PATH
    else
        debug "Can not fount external settings file... Starting with defaults."
fi

# Override default settings if defined in config file
processSettings

# Show debug info (if needed)
dumpDebugSettings

# Input validation
validate "$band" "$album" "$year" "$archive" ${#}

# Generate album path
relPath=`getRelativeAlbumPath "$band" "$album" "$year"`
absPath="$target_path/$relPath"

debug "Album will be unpacked to \"$absPath\""

createDir "$absPath"

case "$archive" in
    *.rar | *.RAR)
        message "Extracting RAR archive..."
        unrar e -ep "$archive" "$absPath";
    ;;
    *.zip | *.ZIP)
        message "Extracting ZIP archive..."
        unzip -j "$archive" -d "$absPath";
    ;;
    *.7z)
        message "Extracting 7z archive..."
        7z e -o"$absPath" "$archive"
    ;;
    *)
        error "Unsupported extension..."
        fail 1
    ;;
esac

if [[ $process_tags -eq 1 ]]
   then
	find "$absPath"  -iname '*.mp3' -print0 | xargs -0 mid3iconv -eCP1251 --remove-v1
fi

# Handle unpacking result
if [[ $? ]] ; then success; else fail 1; fi


