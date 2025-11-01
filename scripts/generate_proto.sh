#!/bin/bash

# Set the source directory

if [ ! -f "pubspec.yaml" ]; then
  echo "Must be executed from the flutter main repo."
  exit 1
fi

# Definitions for twonly Backup
GENERATED_DIR="./lib/src/model/protobuf/client/generated/"
CLIENT_DIR="./lib/src/model/protobuf/client/"

protoc --proto_path="$CLIENT_DIR" --dart_out="$GENERATED_DIR" "backup.proto"
protoc --proto_path="$CLIENT_DIR" --dart_out="$GENERATED_DIR" "messages.proto"
protoc --proto_path="$CLIENT_DIR" --dart_out="$GENERATED_DIR" "groups.proto"

protoc --proto_path="$CLIENT_DIR" --dart_out="$GENERATED_DIR" "push_notification.proto"
protoc --proto_path="$CLIENT_DIR" --swift_out="./ios/NotificationService/" "push_notification.proto"


# Definitions for the Server API

SRC_DIR="../twonly-server/twonly-api/src/"

DST_DIR="$(pwd)/lib/src/model/protobuf/"

mkdir $DST_DIR &>/dev/null

ORIGINAL_DIR=$(pwd)

cd "$SRC_DIR" || {
  echo "Failed to change directory to $SRC_DIR"
  exit 1
}

for proto_file in "api/"**/*.proto; do
  if [[ -f "$proto_file" ]]; then
    protoc --proto_path="." --dart_out="$DST_DIR" "$proto_file"
  else
    echo "No .proto files found in $SRC_DIR"
  fi
done

cd "$ORIGINAL_DIR" || {
  echo "Failed to change back to the original directory"
  exit 1
}

echo "Finished processing .proto files :)"