# Data exploration for bivariate bivalve map.
# 1. find list of closest stations to each beach

# OUTPUT: list of tide stations corresponding to each beach

library(sf)
library(dplyr)
library(stringr)

# - 1) Wolfe Property State Park (BIDN: 250510)
# - 2) Fort Flagler State Park (BIDN: 250260)
# - 3) Chimacum Creek Tidelands (BIDN: 250184)
# - 4) Dosewallips State Park (BIDN:  270200)
# - 5) Harstine Island (BIDN: 280820)
# - 6) Duckabush (270286)
# - 7) Oak Bay Park (250400)
# - 8) Twanoh State Park (270460)
# - 9) Potlatch State Park (270440)
# - 10) Port Gamble Heritage Park (250900)
# - 11) Dabob Bay (270801) 
# - 12) Oakland Bay (281050)
# - 13) North Bay (Case Inlet) (280710)
# - 14) Penrose Point (280680)
# - 15) Eagle Creek (270300)

beaches <- read.csv("data/Recreational_Shellfish_Beaches.csv") 
beachlist <- c(250510, 250260, 250184, 270200, 280820, 270286, 250400, 270460,
               270440, 250900, 270801, 281050, 280710, 280680, 270300)

map_beaches <- beaches %>% 
  filter(BIDN %in% beachlist) %>%
  st_as_sf(coords = c("Midx", "Midy"))


plot(map_beaches[0])

# st_write(map_beaches, "data/processed/beaches.geojson")

### A. TIDE DATA
# pull tide station location 
# source: https://tidesandcurrents.noaa.gov/tide_predictions.html?gid=1415

tide_stations <- read.csv("data/tide_stations.csv")
tide_stations$station_name <- str_trim(tide_stations$station_name)

tide_stations <- st_as_sf(tide_stations, coords = c("lon", "lat"))

# given list of beaches, find closest tide station
beaches_with_tide <- map_beaches %>%
  select(BEACHNAME, BIDN) %>%
  st_join(tide_stations, st_nearest_feature)

write.csv(st_drop_geometry(beaches_with_tide), "data/processed/beaches_with_tide.csv", row.names=FALSE)

plot(tide_stations[0], add = TRUE, col = "red")


### B. HEALTH DATA

# for later
api <- "https://services8.arcgis.com/rGGrs6HCnw87OFOT/arcgis/rest/services/Recreational_Shellfish_Beaches/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"


## next steps
# for each beach — pull today's tide data from corresponding stations
# check if beach has tides below thresholds
# open question: where to store the week's beach data? upload to remote? 
# 2 cron jobs: 
###### 1. daily: pulling daily tide data and a static file for the week's beach data, creating boolean data frame of which beaches are g2g 
###### 2. weekly: pulling new beach data, filtering, updating the link for the beach data with new status 
