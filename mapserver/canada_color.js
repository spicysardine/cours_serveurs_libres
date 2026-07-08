//const map = L.map('map').setView([56, -96], 4);

//=========================================  Main map =========================================//

//adding main map to map division of the page
const MAP_CRS = L.CRS.EPSG3857;
// Tile Server does not send images for zoom level higher than 19
const MAX_ZOOM_LEVEL = 21;
const MIN_ZOOM_LEVEL = 0;
// Use the maxNativeZoom option to have Leaflet keep images from the last available zoom level and scale them up
const MAX_SCALEUP_ZOOM_LEVEL = 18;

let map_options  = {
 crs:MAP_CRS,
 zoomDelta:1,
 wheelPxPerZoomLevel:120,
 preferCanvas:true,
 //maxBounds: [[43.39377,6.29488],[44.70638,8.04942]],
 maxZoom: MAX_ZOOM_LEVEL,
 minZoom: MIN_ZOOM_LEVEL,
 zoomAnimation: true,// true is default 
 fadeAnimation: true, // true is default
 keyboard: true, // true is default
 keyboardPanDelta: 100,
 inertia: true, // true is default
 zoomControl: true, // true is default
 attributionControl: true, // true is default
 noWrap: true // false is default
}

let map = L.map('main_map_division', map_options);

//const MAP_CENTER_SICTIAM = [43.99072, 7.13637]
const MAP_CENTER_DEV     = [44.25850, 6.92086]
const MAP_CENTER_WORLD     = [0.00000, 0.00000]
const MAP_CENTER_NORTH_AMERICA = [49.17795,-97.46744]
const ZOOM = 4;
map.setView(MAP_CENTER_NORTH_AMERICA, ZOOM);

//---------------------------------------- adding background raster tiles

// default OpenStreetMap
let osm_url      = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
let map_attr_obj_osm = {attribution: 'OpenStreetMap', maxZoom: MAX_ZOOM_LEVEL, maxNativeZoom: MAX_SCALEUP_ZOOM_LEVEL};
let tile_osm = L.tileLayer(osm_url, map_attr_obj_osm);
//tile_osm.addTo(map);

// MapBox
const MAPBOX_TOKEN = 'get yourself a token from mapbox';
const MAPBOX_MAPID_3D_BUILDINGS = 'cla3y3gce003g15o4xza15zz0';
const MAPBOX_MAPID_NIGHTMAPPING = 'ck478t76k1ro11ct2jsl5qtmt';


// Local WMS layers:
let canada_raster = L.tileLayer.wms('/cgi-bin/mapserv?map=CANADA_COLOR_WEB', {
    layers: 'canada_raster',
    format: 'image/png',
    transparent: true,
    version: '1.3.0'
})
//.addTo(map);

let canada_borders = L.tileLayer.wms('/cgi-bin/mapserv?map=CANADA_COLOR_WEB', {
    layers: 'canada_borders',
    format: 'image/png',
    transparent: true,
    version: '1.3.0'
})
//.addTo(map);

let canada_metropolitan_areas = L.tileLayer.wms('/cgi-bin/mapserv?map=CANADA_COLOR_WEB', {
    layers: 'canada_metropolitan_areas',
    format: 'image/png',
    transparent: true,
    version: '1.3.0'
})
//.addTo(map);

let canada_lakes_rivers = L.tileLayer.wms('/cgi-bin/mapserv?map=CANADA_COLOR_WEB', {
    layers: 'canada_lakes_rivers',
    format: 'image/png',
    transparent: true,
    version: '1.3.0'
})
//.addTo(map);

let canada_population_centers = L.tileLayer.wms('/cgi-bin/mapserv?map=CANADA_COLOR_WEB', {
    layers: 'canada_population_centers',
    format: 'image/png',
    transparent: true,
    version: '1.3.0'
})
//.addTo(map);


// wmts raster:
//MapCache WMTS layer (REST style – most reliable)
//let wmtsLayer = L.tileLayer(
//    'http://localhost/mapcache/wmts/1.0.0/canada_raster_wmts/{style}/{tileMatrixSet}/{z}/{x}/{y}.png',
//    {
//     style:'default',
//     tileMatrixSet:'canada_3857',
//     layer:'canada_raster',
//     format:'image/png',
//     tileSize: 256,
//    });

//let wmtsLayer = L.tileLayer(
//  'http://localhost/mapcache/wmts/1.0.0/canada_raster_wmts/default/canada_3857/{z}/{x}/{y}.png',
//  {
//    tileSize: 256,
//    maxZoom: 18,
//    attribution: "Canada Raster"
//  }
//).addTo(map);

//var wmtsLayer = new L.TileLayer.WMTS(
//  "http://localhost/mapcache/wmts?",
//  {
//    layer: "canada_raster",
//    tilematrixSet: "canada_raster_wmts",
//    format: "image/png",
//    style: "default",
//    tileSize: 256,
//    version: "1.0.0",
//    service: "WMTS",
//    request: "GetTile"
//  }
//);


let wmtsLayer = L.tileLayer(
  "http://localhost/mapcache/tms/1.0.0/canada_raster_wmts@canada_3857/{z}/{x}/{y}.png",
  {
    tms: true,
  }
)

map.addLayer(wmtsLayer);




//---------------------------------------- adding controls to map

// controls and control options
// scale
let ctrl_options_scale = {position:'bottomleft', 'imperial':false};
let control_scale = L.control.scale(ctrl_options_scale);
control_scale.addTo(map);

// layers
let ctrl_options_layers = {collapsed: true};

//basemaps
let basemaps = {'OpenStreetMap': tile_osm };

//overlays
let overlays = {
'canada_raster': wmtsLayer,
//'canada_borders': canada_borders,
//'canada_metropolitan_areas': canada_metropolitan_areas,
//'canada_lakes_rivers': canada_lakes_rivers,
//'canada_population_centers': canada_population_centers,
};

// argument order is important for layers control: 1-basemaps, 2-overlays, 3-options
let control_layers = L.control.layers(basemaps, overlays, ctrl_options_layers);
control_layers.setPosition('topright');
control_layers.addTo(map);



