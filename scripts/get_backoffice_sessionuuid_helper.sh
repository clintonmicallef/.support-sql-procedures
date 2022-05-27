#Script helper for get_backoffice_password.sql

echo "Enter your Trustly email address: "
read varuser
echo
echo "Enter Gluekey Backoffice Password: "
read varpass

#Runs cURL and exports results to local home folder as output.txt
curl 'https://backoffice.trustly.com/api/Legacy' -H 'Connection: keep-alive' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'cache-control: no-cache' -H 'X-Requested-With: XMLHttpRequest' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36' -H 'Content-Type: application/json' -H 'Origin: https://backoffice.trustly.com' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-Mode: cors' -H 'Sec-FetchDest: empty' -H 'Referer: https://backoffice.trustly.com/?Locale=en_GB' -H 'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8' -H 'Cookie: _ga=GA1.2.1717608729.1583745503' --data-binary '{"method":"NewSessionCookie","params":{"Username":"'"$varuser"'","Password":"'"$varpass"'"},"version":1.1}' --compressed -o ~/output.txt
