#!/usr/bin/env bash
set -euo pipefail

#########################################
# Large GeoTIFF Preparation Script
# For MapServer / MapCache Deployment
#########################################

# Usage:
# ./prepare_raster_for_tileserver.sh input.tif output_basename
#
# Example:
# ./prepare_raster_for_tileserver.sh canada_raw.tif canada_web

#########################################

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <input.tif> <output_basename>"
  exit 1
fi

INPUT="$1"
BASENAME="$2"

REPROJECTED="${BASENAME}_3857.tif"
TILED="${BASENAME}_tiled.tif"
COG_OUTPUT="${BASENAME}_cog.tif"

echo "--------------------------------------------"
echo "Input file:        $INPUT"
echo "Base output name:  $BASENAME"
echo "--------------------------------------------"

#########################################
# Step 1 — Reproject to Web Mercator
#########################################

echo "Reprojecting to EPSG:3857..."

gdalwarp \
  -t_srs EPSG:3857 \
  -r cubic \
  -multi \
  -wo NUM_THREADS=ALL_CPUS \
  "$INPUT" \
  "$REPROJECTED"

echo "Reprojection complete."

#########################################
# Step 2 — Create Internally Tiled GeoTIFF
#########################################

echo "Creating tiled GeoTIFF (256x256 blocks)..."

gdal_translate \
  "$REPROJECTED" \
  "$TILED" \
  -co TILED=YES \
  -co BLOCKXSIZE=256 \
  -co BLOCKYSIZE=256 \
  -co COMPRESS=DEFLATE \
  -co PREDICTOR=2 \
  -co ZLEVEL=6

echo "Internal tiling complete."

#########################################
# Step 3 — Build Overviews (Pyramid)
#########################################

echo "Building internal overviews..."

gdaladdo \
  -r average \
  --config COMPRESS_OVERVIEW DEFLATE \
  --config PREDICTOR_OVERVIEW 2 \
  --config GDAL_NUM_THREADS ALL_CPUS \
  "$TILED" \
  2 4 8 16 32 64 128 256

echo "Overviews complete."

#########################################
# Step 4 — Create Cloud Optimized GeoTIFF
#########################################

echo "Creating Cloud Optimized GeoTIFF..."

gdal_translate \
  "$TILED" \
  "$COG_OUTPUT" \
  -of COG \
  -co COMPRESS=DEFLATE \
  -co BLOCKSIZE=256 \
  -co PREDICTOR=2 \
  -co NUM_THREADS=ALL_CPUS

echo "COG creation complete."

#########################################
# Step 5 — Validation
#########################################

echo "Validating COG structure..."

gdalinfo --checksum "$COG_OUTPUT" > /dev/null

echo "--------------------------------------------"
echo "Raster preparation complete."
echo "Outputs:"
echo "  Reprojected: $REPROJECTED"
echo "  Tiled:       $TILED"
echo "  COG:         $COG_OUTPUT"
echo "--------------------------------------------"
