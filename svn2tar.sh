#!/bin/bash
# To be executed frop project root

REVISION=`svn info | grep '^Revision:' | sed -e 's/^Revision: //'`
URL=`svn info | grep '^URL:' | sed -e 's/^URL: //'`

PROJECT_NAME=`svn info |grep '^Repository Root:' | sed -e 's/^Repository Root: //' | grep -o '[^\/]*$'`

CODE_PATH="/tmp/${PROJECT_NAME}_${REVISION}"
ARCHIVE_PATH="/tmp/${PROJECT_NAME}_${REVISION}.tar.gz"

svn export --force $URL $CODE_PATH
tar -cvzf $ARCHIVE_PATH $CODE_PATH

echo "Your archive is here: ${ARCHIVE_PATH}"