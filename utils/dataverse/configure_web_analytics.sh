#!/usr/bin/env sh
# This script first constructs and copies the html file for the web analytics
# then it sets the web analytics settings in the dataverse container.
# The script takes three arguments:
# Example on dev:  ./configure_web_analytics.sh "dev_dataverse" "http://localhost:8080" "7"
# Note that the web analytics (site)id should be different for each server; 7 is a test id

if [ $# -ne 3 ]; then
  echo "Usage: $0 <dataverse_container_name> <root_url> <id>"
  exit 1
fi
DATAVERSE_CONTAINER=$1
ROOT_URL=$2
WEB_ANALYTICS_ID=$3

# the following is the same for all servers right now, 
# but that might change one day
WEB_ANALYTICS_HOST="stats.dans.knaw.nl"
WEB_ANALYTICS_FILENAME="danstats"

# create a temp dir
TMP_DIR=$(mktemp -d)
echo "Temporary directory: $TMP_DIR"


# use a variable for the JS html insertion code with newlines.  
# note that double quotes needed to be escaped here.
CODE="<script type=\"text/javascript\" id=\"Kiwip\"><!--/*--><![CDATA[/*><!--*/
var _paq = _paq || [];
_paq.push(['trackPageView']);
_paq.push(['enableLinkTracking']);
(function() { var u=\"//${WEB_ANALYTICS_HOST}/\"; _paq.push(['setTrackerUrl', u+'${WEB_ANALYTICS_FILENAME}.php']); _paq.push(['setSiteId', '${WEB_ANALYTICS_ID}']); var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0]; g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'${WEB_ANALYTICS_FILENAME}.js'; s.parentNode.insertBefore(g,s); }
)();
/*-->]]>*/</script>
<noscript><p><img src=\"https://${WEB_ANALYTICS_HOST}/${WEB_ANALYTICS_FILENAME}.php?idsite=${WEB_ANALYTICS_ID}\" style=\"border:0;\" alt=\"\" /></p></noscript>"

# but then the escape '\' are outputted as well'
# so to undo that escaping, replace all \" with " in the code
echo "$CODE" | sed 's/\\"/"/g' > "$TMP_DIR"/web-analytics.html



# note: should use a tmp directory for this,
# but for now, just use the current directory

#echo "$code" > web-analytics.html

# the html fragment is read by the application and inserted into the rendered page, 
# so the file does not need to be available via http(s)


# create directory in the dataverse container
docker exec -it "$DATAVERSE_CONTAINER" mkdir -p /dv/branding

# copy the file to the dataverse container
echo "Copying production web-analytics.html file to dataverse container"
docker cp "$TMP_DIR"/web-analytics.html "$DATAVERSE_CONTAINER":/dv/branding/web-analytics.html

# note that the following also worked: /opt/payara/deployments/dataverse/web-analytics.html
# but that is not optimal, as it is not a volume

# then run the curl command to set the web analytics code
echo "Setting :WebAnalyticsCode to: /dv/branding/web-analytics.html"
curl -X PUT -d '/dv/branding/web-analytics.html' "${ROOT_URL}/api/admin/settings/:WebAnalyticsCode"

# cleanup
#rm "$TMP_DIR"/web-analytics.html
rm -rf "$TMP_DIR"
echo ""
echo "Removed temporary directory: $TMP_DIR"
echo "Done with Web analytics code configuration"
