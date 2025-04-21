#!/bin/bash

# Set the source directory

SRC_DIR="../twonly-server/twonly/src/"

DST_DIR="$(pwd)/lib/src/model/protobuf/"

mkdir $DST_DIR

ORIGINAL_DIR=$(pwd)

cd "$SRC_DIR" || {
  echo "Failed to change directory to $SRC_DIR"
  exit 1
}

# Iterate over all .proto files in the source directory
for proto_file in "api/"*.proto; do
  # Check if the file exists to avoid errors if no .proto files are found

  if [[ -f "$proto_file" ]]; then
    # Run the protoc command
    protoc --proto_path="." --dart_out="$DST_DIR" "$proto_file"
    echo "Processed: $proto_file"
  else
    echo "No .proto files found in $SRC_DIR"
  fi
done

# Change back to the original directory
cd "$ORIGINAL_DIR" || {
  echo "Failed to change back to the original directory"
  exit 1
}

echo "Finished processing .proto files."