library('RPostgreSQL')
library('ggplot2')
library('sf')

drv = PostgreSQL()

con <- dbConnect(drv, dbname='beetroot', user='beetroot', password='root')

query = "SELECT * FROM canada_lakes_rivers WHERE name != '' ;"
query_basemap = "select * from canada_basemap_simplified"
res = dbSendQuery(con, query)
pgdata = dbFetch(res, n=-1)


canada_lakes_rivers <-  st_read(con, query = query)
canada_lakes_rivers_lambstat <- st_transform(canada_lakes_rivers, 3348)

clr <- ggplot(canada_lakes_rivers_lambstat)+
  geom_sf(fill='#4682b4b0', colour="black", size=.1)
# clr
ggsave2('clr.png', plot=clr, device='png', width=16.54, height=11.69, units='in')

canada_basemap <-  st_read(con, query = query_basemap)
canada_basemap_lambstat <- st_transform(canada_basemap, 3348)

cbm <- ggplot(canada_basemap_lambstat)+
  geom_sf(fill='#4682b4b0', colour="black", size=.1)
cbm

ggsave2('cbm.png', plot=cbm, device='png', width=16.54, height=11.69, units='in')

# combined map
clrt <- ggplot(canada_basemap_lambstat)+
  geom_sf(fill='#000000ee', colour="#000000ee", size=.1)+
  geom_sf(data=canada_lakes_rivers_lambstat, fill='#00ff00dd', colour="#26fa06ee", size=.01)
  


ggsave('clrt.png', plot=clrt, device='png', width=16.54, height=11.69, units='in')
ggsave('clrt.pdf', plot=clrt, device='pdf', width=16.54, height=11.69, units='in')






