DEST_DIR="$1"

set -e

cd web
npm install
npm run build

cd ../service
swift build -c release

TMP_DEST_DIR="$DEST_DIR.tmp"
rm -rf "$TMP_DEST_DIR"
mkdir "$TMP_DEST_DIR"

mv .env "$TMP_DEST_DIR/.env"
mv Public "$TMP_DEST_DIR/Public"
mv .build/release/Run "$TMP_DEST_DIR/Run"

test -e "$DEST_DIR/.env" && yes | cp -f "$DEST_DIR/.env" "$TMP_DEST_DIR/.env"
rm -rf "$DEST_DIR"
mv "$TMP_DEST_DIR" "$DEST_DIR"
