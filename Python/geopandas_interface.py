# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
from sqlalchemy import create_engine
import geopandas as gpd
from psycopg2 import connect

con = connect("dbname=beetroot user=beetroot password='root'")
engine = create_engine("postgresql://beetroot:root@127.0.0.1:5432/beetroot")

sql = "SELECT * FROM geography.canada_lakes_rivers WHERE name != '';"

gdf = gpd.read_postgis(sql, con, crs=3348)

gdf.plot()

gdf.to_postgis('geopandas_table', engine, schema='geography')



































