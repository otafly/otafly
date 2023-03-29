DEST_DIR="$1"
PUB_DIR=".pub"

set -e

cd web
npm install
npm run build

cd ../service
swift build -c release

cd ../
rm -rf "$PUB_DIR"
mkdir "$PUB_DIR"

mv service/Public "$PUB_DIR/Public"
mv service/.build/release/Run "$PUB_DIR/Run"

mkdir -p "$DEST_DIR"
cp -rf "$PUB_DIR/*" "$DEST_DIR"
rm -rf "$PUB_DIR"
