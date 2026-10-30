#!/usr/bin/env bash
# Install the council CLI by symlinking bin/council onto the PATH. No Node needed.
#   ./install.sh             -> ~/.local/bin/council
#   ./install.sh /some/dir   -> /some/dir/council
#   ./install.sh --uninstall [dir]
set -euo pipefail

HERE="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${HOME}/.local/bin"
UNINSTALL=0
if [ "${1:-}" = "--uninstall" ]; then UNINSTALL=1; shift; fi
[ -z "${1:-}" ] || DEST_DIR="$1"
LINK="$DEST_DIR/council"

if [ "$UNINSTALL" -eq 1 ]; then
  if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$HERE/bin/council" ]; then
    rm "$LINK"; echo "removed $LINK"
  else
    echo "nothing to remove: $LINK is not a link to this checkout" >&2
  fi
  exit 0
fi

chmod +x "$HERE/bin/council"
mkdir -p "$DEST_DIR"
if [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
  echo "install: $LINK exists and is not a symlink; leaving it alone" >&2; exit 1
fi
ln -sfn "$HERE/bin/council" "$LINK"
echo "linked $LINK -> $HERE/bin/council"
case ":$PATH:" in
  *":$DEST_DIR:"*) ;;
  *) echo "note: $DEST_DIR is not on your PATH" >&2 ;;
esac
echo "set COUNCIL_ENGINE_CLI to your engine CLI, then: council --help"
