#!/bin/bash
#Script to extract downloaded archives whit music
#

# bash --version

declare -a steps

function addRevertStep {
    steps[${#steps[@]}]="$1"
}

function printRevertSteps {
    cmd_count=${#steps[@]}-1
    echo "Commands to revert ($cmd_count}):"
    while [ $cmd_count -ge 0 ]; do
        echo item: "$steps[$cmd_count]" 
        let cmd_count=cmd_count-1
    done
    
    for step in ${!steps[*]}; do
        echo item: "$steps[step]" 
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

function validate {

#debug "Validation 0:\"$0\", 1:\"$1\", 2:\"$2\", 3:\"$3\", 4:\"$4\", 5:\"$5\""

    if [ "$5"  = "0" ]
        then
          error "What to unpack?"
          exit 1
    fi

    if [ ! -f "$4" ]
        then
          error "Archive  $4 does not exists."
          exit 1
    fi

    if [ "$1" == "" ]
        then 
            error "Band name missing."
            exit 1
    fi

    if [ "$2" == "" ]
        then 
            error "Error: Album name missing."
            exit 1
    fi
}

function create_dir {
    
    debug "create_dir param: $1"
    
    if [ -d "$1" ] 
        then
            message "Directory $1 already exists." 
        else
            message "Creating $1 "
            mkdir "$1"
            if [ $? = 0 ]
                then
                    message "Created $1" 
                    addRevertStep "rm -rf $1"
                else
                    error "Can not create $1"
                    exit $?
            fi             
    fi
}

function prepare_path {
    #echo $1 | sed 's/\ /\\ /g'
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
            exit 1
    esac
done

shift $(($OPTIND - 1))

archive=${!#} 

echo "Band:\"$band\", album:\"$album\", year:\"$year\", archive:\"$archive\""

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
        message "Extracting RAR archive"
        unrar e -ep "$archive" "$album_path";
    ;;
    *.zip)
        message "Extracting ZIP archive"
        unzip -j "$archive" -d "$album_path";
    ;;
    *)
        error "Unsupported extension..."
        exit 1
    ;;
esac

if [ $? = 0 ]
    then
        message "Successful extracting :-)";
    else
        error "Error while extracting archive :-(";
fi

printRevertSteps

exit 0

