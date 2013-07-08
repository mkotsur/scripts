#!/bin/sh

filename=$(basename "$2")
extension="${filename##*.}"
filename="${filename%.*}"

if [[ "${extension}" -ne "zip" ]] 
then 
    echo "Second argument should be deployit server archive..."; 
    exit 10;
fi


echo "Replacing ${1} with ${2}"


rootPath=`dirname "${1}"`
oldPath="${1}_old"

rm -rf ${oldPath}

mv "${1}" "${oldPath}"

unzip "${2}" -d "${rootPath}"

newPath="${rootPath}/${filename}" 

cp -R "${oldPath}/repository" "${newPath}"
cp -R "${oldPath}/conf" "${newPath}"
cp -R "${oldPath}/plugins/"* "${newPath}/plugins/"