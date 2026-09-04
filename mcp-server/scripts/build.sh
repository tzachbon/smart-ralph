#!/bin/bash
set -e

VERSION=$(jq -r '.version' package.json)
OUTDIR="dist"

mkdir -p "$OUTDIR"

platforms=(
  "bun-darwin-arm64"
  "bun-darwin-x64"
  "bun-linux-x64"
  "bun-windows-x64"
)

built_count=0
failed_count=0

for platform in "${platforms[@]}"; do
  echo "Building for $platform..."
  outfile="$OUTDIR/ralph-specum-mcp-${platform#bun-}"
  [[ "$platform" == *windows* ]] && outfile="${outfile}.exe"

  if bun build --compile --target="$platform" ./src/index.ts --outfile "$outfile" 2>&1; then
    built_count=$((built_count + 1))
    echo "  Success: $outfile"
  else
    failed_count=$((failed_count + 1))
    echo "  Failed: $platform (cross-compilation may require network access)"
  fi
done

echo ""
echo "Build complete. $built_count succeeded, $failed_count failed."
echo "Binaries in $OUTDIR/:"
ls -la "$OUTDIR/" 2>/dev/null || echo "No binaries found"

# Exit with error if no binaries were built
if [ "$built_count" -eq 0 ]; then
  echo "Error: No binaries were built"
  exit 1
fi
