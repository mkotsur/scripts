#!/bin/bash
#Script to extract downloaded archives whit music
#

# variable keeps steps to be done in case of fail (kinda transaction state)
declare -a steps

# Where to put unpacked stuff
target_path="/home/$USER/Music"

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
        echo " ** Command $cmd_index of $cmd_count: " $cmd
                   

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
    rm -f "$archive"
    message "SUCEEDED TO UNPACK ARCHIVE"
    exit 0
}

function fail  {
    error "FAILED TO UNPACK ARCHIVE"
    doRevertSteps
    exit $1
}

function help {

    echo "Script for extracting music from archives..."
    echo " -- Options --"
    echo "-b [required] Band name"
    echo "-a [required] Album name"
    echo "-y [optional] release Year"
    echo ""
    echo " -- Keys --"
    echo "-v [optional] Verbose"
    echo ""
    echo " -- Usage --"
    echo "./settle_album.sh -b \"Band name\" -a \"Album name\" -y YYYY ~/Downloads/music_archive.rar"
    echo ""
    echo "Currently supported types: zip, rar, 7z. Files will be extracted to $target_path/Band name/YYYY - Album name/*;"
    echo "Directory structure inside archive will be suppressed."
    echo "Script provided as is. Author: Mykhailo Kotsur. http://sotomajor.org.ua"
    echo "You are welcome to suggest or contribute: http://github.com/mkotsur/scripts"
    exit 0

}

# Validates input
function validate {

    if [ ! -d "$target_path" ]; then error "Path \"$target_path\" does not exist"; error "Create it first"; fail 1; fi

    if [ "$5"  = "0" ]; then error "What to unpack?"; error "Last argument should be path to archive."; fail 1; fi

    if [ ! -f "$4" ]; then error "Archive $4 does not exists."; fail 1; fi

    if [[ ! "$4" =~ ^.*\.(zip|rar|7z) ]]; then error "Unsupported type of archive."; fail 1; fi

    if [ "$1" == "" ]; then error "Band name missing."; fail 1; fi

    if [ "$2" == "" ]; then error "Album name missing."; fail 1; fi
}

# Creates dir by specified path
function create_dir {

    debug "create_dir param: $1"

    if [ -d "$1" ]
        then
            message "Directory $1 already exists."
        else
            if mkdir "$1" &> /dev/null
                then
                    message "Created $1"
                    addRevertStep "rm -rf \"$1\""
                else
                    error "Can not create $1"
                    fail 1
            fi
    fi
}

##################
#   Main logic   #
##################

if [[ $# -eq 0 ]]; then help; fi;

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
            help
            ;;
        *)
            fail 1
    esac
done

shift $(($OPTIND - 1))


args=$#
archive=${!args}

debug "Band:\"$band\"" 
debug "Album:\"$album\""
debug "Year:\"$year\""
debug "Archive:\"$archive\""
debug "Verbose: \"$verbose\""

# Input validation
validate "$band" "$album" "$year" "$archive" ${#}

create_dir "$target_path/$band"

# Generate album path
if [[ '' != "$year" ]]
    then
        album_path="$target_path/$band/$year - $album"
    else
        album_path="$target_path/$band/$album"
fi

create_dir "$album_path"

case "$archive" in
    *.rar)
        message "Extracting RAR archive..."
        unrar e -ep "$archive" "$album_path";
    ;;
    *.zip)
        message "Extracting ZIP archive..."
        unzip -j "$archive" -d "$album_path";
    ;;
    *.7z)
        message "Extracting 7z archive..."
        7z e -o"$album_path" "$archive"
    ;;
    *)
        error "Unsupported extension..."
        fail 1
    ;;
esac

# Handle unpacking result
if [ $? = 0 ] ; then success; else fail 1; fi

