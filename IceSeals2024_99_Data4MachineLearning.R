# Ice Seals 2024: Create VIAME Files and Copy Images for ML Training
# S. Koslovsky

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


# Get data from DB
con <- RPostgreSQL::dbConnect(PostgreSQL(), 
                              dbname = Sys.getenv("pep_db"), 
                              host = Sys.getenv("pep_ip"), 
                              user = Sys.getenv("pep_admin"), 
                              password = Sys.getenv("admin_pw"))
# Copy images
data <- RPostgreSQL::dbGetQuery(con, "SELECT image_dir || \'\\' || image_name AS image FROM surv_ice_seals_2024.tbl_images WHERE ml_imagestatus = \'training\' AND image_type = \'rgb_image\'")
file.copy(data$image, "//akc0ss-n086/NMML_Polar_Imagery_3/ForModelDevelopment_2024_ColorModel/IceSeals_2024_Color_Training")

# Create image list
images <- RPostgreSQL::dbGetQuery(con, "SELECT image_name FROM surv_ice_seals_2024.tbl_images WHERE ml_imagestatus = \'training\' AND image_type = \'rgb_image\' ORDER BY image_name")
write.table(images, "//akc0ss-n086/NMML_Polar_Imagery_3/ForModelDevelopment_2024_ColorModel/IceSeals_2024_Color_Training/IceSeals_2024_TrainingImages_20240729_ImageList.txt", row.names = FALSE, col.names = FALSE, quote = FALSE)

RPostgreSQL::dbDisconnect(con)
