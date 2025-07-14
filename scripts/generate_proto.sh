#!/bin/bash

# Set the source directory

if [ ! -f "pubspec.yaml" ]; then
  echo "Must be executed from the flutter main repo."
  exit 1
fi

# Definitions for twonly Safe
protoc --proto_path="./lib/src/model/protobuf/backup/" --dart_out="./lib/src/model/protobuf/backup/" "backup.proto"

# Definitions for the Push Notifications
protoc --proto_path="./lib/src/model/protobuf/push_notification/" --dart_out="./lib/src/model/protobuf/push_notification/" "push_notification.proto"
protoc --proto_path="./lib/src/model/protobuf/push_notification/" --swift_out="./ios/NotificationService/" "push_notification.proto"


# Definitions for the Server API

SRC_DIR="../twonly-server/twonly/src/"

DST_DIR="$(pwd)/lib/src/model/protobuf/"

mkdir $DST_DIR

ORIGINAL_DIR=$(pwd)

cd "$SRC_DIR" || {
  echo "Failed to change directory to $SRC_DIR"
  exit 1
}

for proto_file in "api/"**/*.proto; do
  if [[ -f "$proto_file" ]]; then
    # Run the protoc command
    protoc --proto_path="." --dart_out="$DST_DIR" "$proto_file"
    echo "Processed: $proto_file"
  else
    echo "No .proto files found in $SRC_DIR"
  fi
done

cd "$ORIGINAL_DIR" || {
  echo "Failed to change back to the original directory"
  exit 1
}

echo "Finished processing .proto files."