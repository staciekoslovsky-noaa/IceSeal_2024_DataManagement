# Create functions -----------------------------------------------
# Function to install packages needed
install_pkg <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x,dep=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

# Install libraries ----------------------------------------------
install_pkg("RPostgreSQL")
install_pkg("rjson")
install_pkg("plyr")
install_pkg("stringr")
install_pkg("tidyverse")

# Connect to DB
con <- RPostgreSQL::dbConnect(PostgreSQL(), 
                              dbname = Sys.getenv("pep_db"), 
                              host = Sys.getenv("pep_ip"), 
                              user = Sys.getenv("pep_user"), 
                              password = Sys.getenv("user_pw"))

# Get list of images from DB
images <- RPostgreSQL::dbGetQuery(con, "SELECT i.image_name, i.flight, camera_model, f.dt, f.fate, i.image_dir
                                FROM surv_ice_seals_2024.tbl_images i
                                LEFT JOIN surv_ice_seals_2024.geo_images_meta m USING (flight, camera_view, dt)
                                LEFT JOIN surv_ice_seals_2024.geo_images_footprint f USING (image_name)
                                WHERE i.image_type = \'rgb_image\'
                                AND i.flight = \'fl05\'
                                AND (i.camera_view = \'C\' OR i.camera_view = \'L\') 
                                ORDER BY image_name") %>% # Exclude R camera view for fewer images
  filter(fate == 'collected_via_nth' | fate == 'collected_via_detections') %>% 
  mutate(row = 1:nrow(images)) %>%
  mutate(group = ifelse(row <= (max(row) / 2), "A", "B")) %>%
  mutate(image_path = paste0(image_dir, "/", image_name))

RPostgreSQL::dbSendQuery(con, "UPDATE surv_ice_seals_2024.tbl_images SET rgb_manualreview = NULL")

for (i in 1:nrow(images)) {
  RPostgreSQL::dbSendQuery(con, paste("UPDATE surv_ice_seals_2024.tbl_images SET rgb_manualreview = \'Y\' WHERE flight = \'fl05\' AND dt = \'", images$dt[i], "\'", sep = '' ))
}

RPostgreSQL::dbSendQuery(con, "UPDATE surv_ice_seals_2024.tbl_images SET rgb_manualreview = \'N\' WHERE rgb_manualreview IS NULL")

write.table(images %>% filter(group == 'A') %>% select(image_path), "//akc0ss-n086/NMML_Polar/Data/Annotations/ice_seals_2024_20250129_manualReview_X/ice_seals_2024_manualReview_rgb_images_20250523_groupA.txt", 
            quote = FALSE, row.names = FALSE, col.names = FALSE)
write.table(images %>% filter(group == 'B') %>% select(image_path), "//akc0ss-n086/NMML_Polar/Data/Annotations/ice_seals_2024_20250129_manualReview_X/ice_seals_2024_manualReview_rgb_images_20250523_groupB.txt", 
            quote = FALSE, row.names = FALSE, col.names = FALSE)
