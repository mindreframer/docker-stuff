
H="http://localhost:5000"
H="http://localhost:8080"
C="curl -s -o -"
Cs="curl -s -o /dev/null -w %{http_code}"

rm -rf ../images
rm -rf /tmp/registry && mkdir /tmp/registry

