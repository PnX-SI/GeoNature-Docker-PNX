source $1
error=""

# GEONATURE FRONTEND
url_test="${GEONATURE_URL_APPLICATION}/"
res=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "${url_test}")
echo "$url_test -> $res"
[ "$res" = "200" ] || error=1

# GEONATURE BACKEND
url_test="${GEONATURE_API_ENDPOINT}/gn_commons/config"
res=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "${url_test}")
echo "$url_test -> $res"
[ "$res" = "200" ] || error=1

# USERSHUB
url_test="${USERSHUB_URL_APPLICATION}/login"
res=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "${url_test}")
echo "$url_test -> $res"
[ "$res" = "200" ] || error=1

# TAXHUB
url_test="${TAXHUB_URL_APPLICATION}/"
res=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "${url_test}")
echo "$url_test -> $res"
[ "$res" = "200" ]  || error=1

# ATLAS
url_test="${ATLAS_URL_APPLICATION}/"
res=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "${url_test}")
echo "$url_test -> $res"
[ "$res" = "200" ] || error=1

# PGADMIN
url_test="${BASE_URL}${PGADMIN_PREFIX}/login?next=%2Fpgadmin%2F"
res=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "${url_test}")
echo "$url_test -> $res"
[ "$res" = "200" ] || error=1


# check error
[ ! -z "$error" ] && exit 1 || exit 0
