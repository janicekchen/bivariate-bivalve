library(geojsonio)
library(jsonlite)
library(httr)
library(sf)
library(lubridate)
library(dplyr)

## READING IN DATA FRAME CONTAINING MY BEACHES AND THEIR CORRESPONDING TIDE STATIONS
## I'll be using this list to filter WDFW beaches, and pull NOAA tide data
my_beaches <- read.csv("../data/processed/beaches_with_tide.csv") %>%
  distinct()

read.csv("./")
## PULLING WASHINGTON STATE DEPARTMENT OF FISH AND WILDLIFE BEACH DATA

beach_url <- "https://services8.arcgis.com/rGGrs6HCnw87OFOT/arcgis/rest/services/Recreational_Shellfish_Beaches/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson" # API endpoint
beach_raw <- GET(beach_url) # API request
beach_data <- fromJSON(rawToChar(beach_raw$content)) # extracting JSON from API request
beach_data_df <-beach_data$features$properties # converting to data frame (extracting properties)

# I only need columns BIDN (unique beach ID), BEACHNAME, FINALSTATUS — selecting columns...
beach_data_df <- beach_data_df %>%
  filter(OBJECTID != 315) %>% # penrose point is a duplicate, removing second value
  select(BEACHNAME, BIDN, FINALSTATUS)

# filtering to the beaches I want
beach_filtered <- beach_data_df %>%
  filter(BIDN %in% my_beaches$BIDN)

beach_filtered$BIDN <- as.integer(beach_filtered$BIDN)

# joining to my beaches data frame
my_beaches <- my_beaches %>%
  left_join(beach_filtered)

## READING IN TIDE DATA
# generating list of unique tide station IDs from my_beaches list
tide_stations <- unique(my_beaches$station_id)

noaa_api_url <- "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?" # NOAA's API request URL
noaa_params <- "date=today&product=predictions&datum=MLLW&time_zone=lst_ldt&interval=hilo&units=english&application=BivariateBivalve&format=json"

# End goal: data frame of tide stations, with boolean indicating whether or not a daytime low tide for clamming and geoducking will exist
tide_boolean <- data.frame(matrix(nrow=0, ncol=3)) # generating an empty data frame to append boolean values to
names(tide_boolean) <- c("station_id", "clam_tide_check", "geoduck_tide_check") #renaming columns

# looping through tide stations
lapply(tide_stations, function(station){
  tides_raw <- GET(paste0(noaa_api_url, noaa_params, "&station=", station)) # API request
  tides_data <- fromJSON(rawToChar(tides_raw$content)) # parsing to JSON
  tides_df <- tides_data$predictions %>%
    filter(type == "L")# parsing to data frame
  
  tides_df$hour <- hour(tides_df$t) # converting date/time column to a hour column 
  
  # check to see if there is a daytime low 
  tides_df$daytimelow <- tides_df$hour >= 8 & tides_df$hour <= 18 
  
  # check to see if a clam tide and a daylight low is true
  tides_df$clamtide <- ifelse(tides_df$v <= -0.5 & tides_df$daytimelow, TRUE, FALSE) 
  
  # check to see if a geoduck_tide tide and a daylight low is true
  tides_df$geotide <- ifelse(tides_df$v <= -2 & tides_df$daytimelow, TRUE, FALSE)
  
  # creating data row of whether clamming is available at the station to append to tide_boolean df
  t <- data.frame(station_id = station, 
                  clam_tide_check = ifelse(TRUE %in% tides_df$clamtide, TRUE, FALSE),
                  geoduck_tide_check = ifelse(TRUE %in% tides_df$geotide, TRUE, FALSE))
  
  # bind to big boolean data frame
  tide_boolean <<- rbind(tide_boolean, t)

})

# now we have a data frame that shows whether tides will be good for clamming and geoducking
# joining this to my list of beaches
my_beaches <-  my_beaches %>%
  left_join(tide_boolean)

# change clam column to FALSE if geoduck column is TRUE
my_beaches$clam_tide_check <- ifelse(my_beaches$geoduck_tide_check == TRUE, FALSE, my_beaches$clam_tide_check)

# creating column to map colors onto LEDs
my_beaches$LED_status <- ifelse(my_beaches$FINALSTATUS == "Closed", 0,
                                ifelse(my_beaches$clam_tide_check == TRUE, 1,
                                       ifelse(my_beaches$geoduck_tide_check == TRUE, 2, 0)))

write.csv(my_beaches, "../data/processed/beaches_ledstatus.csv")