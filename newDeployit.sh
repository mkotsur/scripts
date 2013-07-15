#!/bin/sh

currentPath=${1%/}
distPath="$2"

if [[ -d "$2" ]]
    then
        [[ ! -d "$2/cli" || ! -d "$2/server" ]] && echo "$2 does not seem to be Deployed source dir" && exit 10
        cd "$2" && gradle buildRelease
        f=`find . -name "deployit-*-server.zip"`
        echo "Found new deployit server: ${f}"
        distPath="$2/$f"
fi

filename=$(basename "$distPath")
extension="${filename##*.}"
filename="${filename%.*}"

if [[ "${extension}" -ne "zip" ]] 
then 
    echo "Second argument should be deployit server archive..."; 
    exit 10;
fi

echo "Replacing ${currentPath} with ${distPath}"

rootPath=`dirname "${currentPath}"`
oldPath="${currentPath}_old"

rm -rf ${oldPath}

mv "${currentPath}" "${oldPath}"

unzip "${distPath}" -d "${rootPath}"

newPath="${rootPath}/${filename}" 

cp -R "${oldPath}/repository" "${newPath}"
cp -R "${oldPath}/conf" "${newPath}"
cp -R "${oldPath}/plugins/"* "${newPath}/plugins/"