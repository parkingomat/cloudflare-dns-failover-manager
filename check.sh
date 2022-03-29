#!/bin/bash

# Calculated variable values
RESULT=0
PORT=80
PROTOCOL="$(echo $SEARCHURL | grep :// | sed -e's,^\(.*://\).*,\1,g')"
if [ PROTOCOL=="https://" ]
then
PORT=443
fi
DNSRECORD=$(echo $SEARCHURL | awk -F[/:] '{print $4}')
IFS=' ' read -r -a SEARCHIPS <<< $SEARCHIPS



# Get the zone id 
ZONEID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$SEARCHZONE&status=active" \
  -H "Authorization: Bearer $CLOUDFLAREACCESSTOKEN" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')



# Perform health check for each IP address to see if you get a valid response
for i in "${SEARCHIPS[@]}"
do
    echo "Cheking IP: $i"

    # Get response according to parameters
    HTTP_RESPONSE=$(curl -m $SEARCHTIMEOUT --silent --write-out "HTTPSTATUS:%{http_code}" -X $SEARCHMETHOD $SEARCHURL --resolve $DNSRECORD:$PORT:$i --insecure)

    # Get response body only
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')

    # Get status only
    HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    echo "Response code is $HTTP_STATUS from $i"

    #Check if status matches required status and if response body includes required string
    if [ $HTTP_STATUS == $SEARCHEXPECTEDCODE  ]
    then

        echo "$i responded with correct status $HTTP_STATUS"

        # If status matches, check if body contains required string
        if [ $SEARCHSTRING != "" ]
        then
            if [ $(echo $HTTP_BODY | grep $SEARCHSTRING | wc -l) -gt 0 ]
            then
                echo "in $i requested string found"
            else
                echo "in $i requested string was not found"
                RESULT=1 
            fi   
        fi
    else
        echo "$i responded with status $HTTP_STATUS and expecting $SEARCHEXPECTEDCODE"
        RESULT=1
    fi


    # Get the id for the current redord combination (IP + Hostname)
    DNSRECORDID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records?type=A&name=$DNSRECORD&content=$i" \
    -H "Authorization: Bearer $CLOUDFLAREACCESSTOKEN" \
    -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')



    # Create record if response is valid but record is missing
    if [ $RESULT == 0 ] && [ $DNSRECORDID == null ]
    then

        curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records" \
        -H "Authorization: Bearer $CLOUDFLAREACCESSTOKEN" \
        -H "Content-Type: application/json" \
        --data  '{"type":"A","name":"'$DNSRECORD'","content":"'$i'","proxied":'$CLOUDFLAREPROXY'}'
    
        echo "adding $i as IP"

    # Remove record if response is valid but record is missing
    elif [ $RESULT == 1 ] && [ $DNSRECORDID != null ]
    then

        # Count records to ensure there is at least one record left
        DNSRECORDCOUNT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records?type=A&name=$DNSRECORD" \
        -H "Authorization: Bearer $CLOUDFLAREACCESSTOKEN" \
        -H "Content-Type: application/json" | jq -r '{"result"}[] | length')

        if [ $DNSRECORDCOUNT -gt 1 ]
        then

            curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$DNSRECORDID" \
            -H "Authorization: Bearer $CLOUDFLAREACCESSTOKEN" \
            -H "Content-Type: application/json"

            echo "deleting $i as IP"
        fi
    
    fi
done
exit 0