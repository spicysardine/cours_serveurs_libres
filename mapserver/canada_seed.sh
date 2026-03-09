#!/bin/bash


#-c, --config file
#Path to the mapcache.xml configuration file that contains
#the tilesets that need to be seeded.

#-t, --tileset name
#Name of the tileset that must be seeded.

#-g, --grid name
#Name of the grid that must be seeded 
#(the selected tileset must reference the given grid).

#-n, --nthreads number
#Number of parallel threads that should be used to request tiles
#from the WMS source. The default is 1, but can be set higher if the 

#-f, --force
#Force tile recreation even if it already exists.

#-e, --extent minx,miny,maxx,maxy
#(Optional) Bounding box of the area to seed.


mapcache_seed \
  -c /etc/mapcache/mapcache.xml \
  -t canada_lakes_rivers \
  -e -6724725,5892457,-5822118,6797364 \
  -g canada_3857 \
  -z 11,14 \
  -n 23 \
  -f


# canada extent
#  -e -16771439.285,3685908.646,-3767831.687,10172409.571 \

# newfoundland extent
#  -e -6724725,5892457,-5822118,6797364 \
