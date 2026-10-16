#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
rust_dir=$(dirname -- "$script_dir")
database_path="$rust_dir/sqlx-dev.sqlite"

rm -f -- "$database_path"

for migration in "$rust_dir"/src/database/app/migrations/*.sql; do
    sqlite3 "$database_path" ".read $migration"
done

for migration in "$rust_dir"/src/database/signal/migrations/*.sql; do
    sqlite3 "$database_path" ".read $migration"
done

cd "$rust_dir"
cargo sqlx prepare -- --all-targets

echo "Prepared SQLx schema database and offline query metadata."
