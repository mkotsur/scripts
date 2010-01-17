#!/bin/bash
#Script to extract downloaded archives whit music
#

# variable keeps steps to be done in case of fail (kinda transaction state)
declare -a steps

function addRevertStep {
    steps[${#steps[@]}]="$1"
}


function printRevertSteps {
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
    echo " o_O Debug: "$1
}

function success {
    message "SUCEEDED TO UNPACK ARCHIVE"
    printRevertSteps
    exit 0
}

function fail  {
    error "FAILED TO UNPACK ARCHIVE"
    printRevertSteps
    exit $1
}

function validate {

#debug "Validation 0:\"$0\", 1:\"$1\", 2:\"$2\", 3:\"$3\", 4:\"$4\", 5:\"$5\""

    if [ "$5"  = "0" ]
        then
          error "What to unpack?"
          exit 1
    fi

    if [ ! -f "$4" ]
        then
          error "Archive $4 does not exists."
          exit 1
    fi
    if [[ ! "$4" =~ ^.*\.(zip|rar) ]]
        then
            error "Unsupported type of archive."
            fail 1
    fi
    if [ "$1" == "" ]
        then
            error "Band name missing."
            fail 1
    fi

    if [ "$2" == "" ]
        then
            error "Album name missing."
            fail 1
    fi
}

function create_dir {

    debug "create_dir param: $1"

    if [ -d "$1" ]
        then
            message "Directory $1 already exists."
        else
            message "Creating $1 "

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

function prepare_path {
    echo $1
}

##################


target_path="/home/$USER/Music"


while getopts "b:a:y:" optname
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
        [?])
            echo "Invalid option "$optname"\n"
            fail 1
    esac
done

shift $(($OPTIND - 1))

archive=${!#}

debug "Band:\"$band\", album:\"$album\", year:\"$year\", archive:\"$archive\""

# Input validation
validate "$band" "$album" "$year" "$archive" ${#}

# Starting work
#printf "Processing %s with album %s\n" $band $album

# Create band dir
create_dir "$(prepare_path "$target_path/$band")"

#Generate album path
if [ "" != "$year" ]
    then
        album_path="$(prepare_path "$target_path/$band/$year - $album")"
    else
        album_path="$(prepare_path "$target_path/$band/$album")"
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
    *)
        error "Unsupported extension..."
        fail 1
    ;;
esac

# Handle unpacking result
if [ $? = 0 ] ; then success; else fail 1; fi

