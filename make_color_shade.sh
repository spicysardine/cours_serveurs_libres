#!/bin/bash

gdal_calc.py \
  -A canada_color_relief.tif --A_band=1 \
  -B canada_hillshade.tif \
  --calc="A*(B/255)" \
  --type=Byte \
  --outfile=tmp_r.tif \
  --overwrite

gdal_calc.py \
  -A canada_color_relief.tif --A_band=2 \
  -B canada_hillshade.tif \
  --calc="A*(B/255)" \
  --type=Byte \
  --outfile=tmp_g.tif \
  --overwrite

gdal_calc.py \
  -A canada_color_relief.tif --A_band=3 \
  -B canada_hillshade.tif \
  --calc="A*(B/255)" \
  --type=Byte \
  --outfile=tmp_b.tif \
  --overwrite

gdal_merge.py \
  -separate \
  -o shaded_color_relief.tif \
  tmp_r.tif tmp_g.tif tmp_b.tif
