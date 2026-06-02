# =============================================================================
# 03_plants_per_25km.R
# OVERLAY 2: Buffer + Join
#
# Question: Which counties have at least one powerplant facility within 25 km?
# =============================================================================

# Set your working directory in 01_analysis.R, then run this script.
source("scripts/01_setup.R")

# ---- Confirm we are in a projected CRS (units = meters) ---------------------
# This matters! In a geographic CRS (degrees), st_buffer(dist = 5000) would
# buffer by 5,000 degrees, which is meaningless.
stopifnot(sf::st_is_longlat(plants) == FALSE)

# ---- Buffer the points ------------------------------------------------------

buffer_dist_m <- 25000 # 25 km

plants_buf <- st_buffer(plants, dist = buffer_dist_m)

# ---- Find counties intersecting any buffer ---------------------------------
# st_intersects(A, B) returns, for each row of A, the indices of rows in B
# that touch it. lengths() gives the count; > 0 flips it to a logical.

counties_near <- counties |>
  mutate(
    n_facilities_within_25km = lengths(st_intersects(geometry, plants_buf)),
    near_plants = n_facilities_within_25km > 0
  )

# ---- Sanity check -----------------------------------------------------------
cat(
  "Counties with >=1 powerplant within 25 km: ",
  sum(counties_near$near_plants), " of ", nrow(counties_near), "\n"
)

# ---- Plot -------------------------------------------------------------------
# Wrapped in print() so the map appears whether you run the script line-by-line
# OR click "Source" (Source turns off auto-printing of the plot object).
quartz()
print(
  ggplot(counties_near) +
    geom_sf(aes(fill = near_plants), color = "white", linewidth = 0.1) +
    geom_sf(data = plants, color = "black", size = 0.4) +
    scale_fill_manual(
      name   = "Near powerplants?",
      values = c(`TRUE` = "#E57200", `FALSE` = "#E5E5E5")
    ) +
    labs(title = "Counties within 25 km of any powerplant") +
    theme_void()
)


# =============================================================================
# MODIFY 1:  Change the buffer distance from 100 km to 1 km.
#            Re-source the script. How does the map shift?
#
# MODIFY 2:  Map the *count* of facilities within 25 km (already computed above
#            as `n_facilities_within_25km`) instead of the boolean. Switch the
#            ggplot aes to `fill = n_facilities_within_25km` and use
#            scale_fill_viridis_c().
# =============================================================================

# 1

buffer_dist_m <- 1000 # 1 km

plants_buf <- st_buffer(plants, dist = buffer_dist_m)

# ---- Find counties intersecting any buffer ---------------------------------
# st_intersects(A, B) returns, for each row of A, the indices of rows in B
# that touch it. lengths() gives the count; > 0 flips it to a logical.

counties_near_1km <- counties |>
  mutate(
    n_facilities_within_1km = lengths(st_intersects(geometry, plants_buf)),
    near_plants = n_facilities_within_1km > 0
  )

# ---- Sanity check -----------------------------------------------------------
cat(
  "Counties with >=1 powerplant within 1 km: ",
  sum(counties_near_1km$near_plants), " of ", nrow(counties_near_1km), "\n"
)

# ---- Plot
quartz()
print(
  ggplot(counties_near_1km) +
    geom_sf(aes(fill = near_plants), color = "white", linewidth = 0.1) +
    geom_sf(data = plants, color = "black", size = 0.4) +
    scale_fill_manual(
      name   = "Near powerplants?",
      values = c(`TRUE` = "#E57200", `FALSE` = "#E5E5E5")
    ) +
    labs(title = "Counties within 1 km of any powerplant") +
    theme_void()
)

# 2
quartz()
print(
  ggplot(counties_near_1km) +
    geom_sf(aes(fill = n_facilities_within_1km), color = "white", linewidth = 0.1) +
    scale_fill_viridis_c(name = "Facilities within 1km", option = "magma", trans = "sqrt") +
    labs(title = "Count of powerplants within 1 km by county") +
    theme_void()
)
