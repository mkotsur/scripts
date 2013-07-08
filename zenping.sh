#!/bin/sh

TAG=`echo "$3" | tr '[A-Z]' '[a-z]'`
EMAIL="$1"
PASSWORD="$2"

QUERY="[?(status='open' || status='new')]"
SCRIPT="if (_.contains(this.tags,'${TAG}')) out(this.id + ' : ' + this.subject)"


while true 
do
    msg=`curl -s https://xebialabs.zendesk.com/api/v2/tickets/recent.json -u "${EMAIL}":"${PASSWORD}" | jsawk "return this.tickets" | jsawk -q "${QUERY}" -n "${SCRIPT}" | sed -e "s/'/\\\'/g" `
    
    echo  "`date '+%m.%d.%y %H:%M:%S'` : ${msg}"
    echo "${msg}" | xargs -I {} terminal-notifier -title ZenDesk -message '{}'; sleep 600;
    if [ $? -ne 0 ]; then
        echo "Exited with error code $?"
    fi
done

    
