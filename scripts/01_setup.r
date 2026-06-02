# ---- Set your working directory ---------------------------------------------
# >>> EDIT THIS LINE <<<  Point it at the folder that contains the `data/` and `scripts/` subfolders. Then source this script.
setwd("/Users/alihunter/Documents/EIL Summer/day06-spatial-data")

# ---- Packages ---------------------------------------------------------------

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(sf, terra, exactextractr, dplyr, tidyr, ggplot2, units, httpgd)


pacman::p_load(
  sf, # vector data
  terra, # raster data
  exactextractr, # area-weighted raster->polygon
  dplyr, # data manipulation
  tidyr, # replace_na
  ggplot2, # plotting
  units # working with km^2 etc.
)
# ---- File paths -------------------------------------------------------------

data_path <- "data/data_afternoon/"

counties_file <- paste0(data_path, "us_counties.shp")
plants_file <- paste0(data_path, "us_powerplants.shp")
pm25_file <- paste0(data_path, "us_pm25.tif")

# ---- Common CRS -------------------------------------------------------------
# EPSG:5070 = NAD83 / Conus Albers. Equal-area, units = meters.
# Sensible default for any analysis covering the continental US.

target_crs <- 5070

counties <- st_read(counties_file, quiet = TRUE) |>
  st_transform(target_crs) |>
  st_make_valid()

plants <- st_read(plants_file, quiet = TRUE) |>
  st_transform(target_crs)

pm25 <- rast(pm25_file)
if (is.na(crs(pm25)) || crs(pm25) == "") {
  crs(pm25) <- "EPSG:4326" # PM2.5 surfaces are typically distributed in WGS84
}
pm25 <- terra::project(pm25, paste0("EPSG:", target_crs))

# ---- Sanity checks ----------------------------------------------------------

stopifnot(st_crs(counties) == st_crs(plants))
stopifnot(st_crs(counties)$epsg == target_crs)

cat("Setup complete.\n")
cat(" counties: ", nrow(counties), "polygons,  CRS =", st_crs(counties)$epsg, "\n")
cat(" plants:      ", nrow(plants), "points,    CRS =", st_crs(plants)$epsg, "\n")
cat(
  " pm25:     ", ncol(pm25), "x", nrow(pm25), "raster, CRS =",
  crs(pm25, describe = TRUE)$code, "\n"
)
