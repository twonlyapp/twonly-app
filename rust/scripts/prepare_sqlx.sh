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
# Allow preparing just the app library with --lib, without compiling API tests.
if [ "$#" -eq 0 ]; then
    set -- --all-targets
fi
SQLX_OFFLINE=false cargo sqlx prepare -- "$@"

echo "Prepared SQLx schema database and offline query metadata."
