VERSION="$(jq -r '.version' package.json)"

docker build --build-arg VERSION=$VERSION -f docker/Dockerfile -t yilee01/chat2api .
if [ $? -eq 0 ]; then
  docker tag yilee01/chat2api:latest yilee01/chat2api:$VERSION
  echo "build success"
else
  echo "build failed"
  exit 1
fi
