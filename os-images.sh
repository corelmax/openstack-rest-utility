#!/bin/bash

API_URL=http://103.212.36.163:9292
LOGIN_URL=https://103.212.36.163:5000/v3/auth/tokens
ADMIN_USER=admin
ADMIN_PASS=

LOGIN_POST_BODY='{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'$ADMIN_USER'","domain":{"name":"Default"},"password":"'$ADMIN_PASS'"}}},"scope":{"system":{"all":true}}}}'
#echo "curl with ${LOGIN_POST_BODY}"
OUT_HEADER=$(curl --insecure -sSL -D - -H 'Content-Type: application/json' -XPOST -d $LOGIN_POST_BODY -o /dev/null $LOGIN_URL)
ADMIN_TOKEN=$(echo -n "$OUT_HEADER" | awk '/^X-Subject-Token/ { TOKEN = $2 } END { printf("%s", TOKEN) }' | sed 's/[^a-zA-Z0-9_-]//g')

MARKER=null

if [ -z "$ADMIN_TOKEN" ]
then
	echo "Unauthorized"
	exit 1
fi

echo "Login Authorized!"

sleep 1

_list () {
	URL="$API_URL/v2/images"
	if [ "$MARKER" != null ]
	then
		URL="$URL?marker=$MARKER"
	fi

	JSON_OUT=$(curl --insecure -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: $ADMIN_TOKEN" "$URL")
	echo $JSON_OUT | jq -r '.images[] | .id + " " + .name + " " + .locations[0].url' | \
	while IFS= read -r LINE; do
		echo $LINE
		#echo "$NAME --- $FILE";
	done
	if [[ $JSON_OUT =~ .*\"next\":\ *([^\"]*).* ]]
	then
		MARKER=$(echo $JSON_OUT | sed 's/.*"next":\ *"\([^"]*\)".*/\1/' | sed 's/\/v2\/images\?marker=\(.*\)/\1/')
		if [ "$MARKER" != null ]
		then
			_list
		fi
	else
		MARKER=null
	fi
}

if [ "$1" == "list" ]
then
	echo "Getting list of images"
	_list
	exit 0
fi


