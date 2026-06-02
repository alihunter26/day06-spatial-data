# =============================================================================
# 02_overlay_points.R
# OVERLAY 1: Point-in-Polygon
#
# Question: How many powerplants are in each county?
# =============================================================================

# Set your working directory in analysis.R, then run this script.
source("scripts/01_setup.R")

# ---- The join ---------------------------------------------------------------
# st_within: for each plant point, find the county that contains it.
# After the join, each row of `plants_with_county` is a facility, with its
# county's attributes attached.

plants_with_county <- st_join(plants, counties, join = st_within)

# ---- Aggregate to county level ----------------------------------------------

facility_counts <- plants_with_county |>
  st_drop_geometry() |>
  count(GEOID, name = "n_facilities")

counties_pip <- counties |>
  left_join(facility_counts, by = "GEOID") |>
  mutate(n_facilities = tidyr::replace_na(n_facilities, 0L))

# ---- Sanity check -----------------------------------------------------------
cat("Total powerplants:        ", nrow(plants), "\n")
cat("Sum of facilities-per-county:", sum(counties_pip$n_facilities), "\n")
# These should match exactly only if every point falls within some county.
# In practice they often don't -- facilities geocoded to a coastline or just
# outside a generalized boundary will not match. The gap (24 in our case) is
# itself a useful diagnostic: if it's large, your geocoding has problems.

# ---- Plot -------------------------------------------------------------------
# Wrapped in print() so the map appears whether you run the script line-by-line
# OR click "Source" (Source turns off auto-printing of the plot object).

p <- ggplot(counties_pip) +
  geom_sf(aes(fill = n_facilities), color = "white", linewidth = 0.1) +
  scale_fill_viridis_c(name = "Facilities", option = "magma", trans = "sqrt") +
  labs(title = "Powerplant facilities per county") +
  theme_void() +
  theme(legend.position = "right")

print(p)
ggsave("outputs/maps/facilities_per_county.png", plot = p, width = 10, height = 6, dpi = 150)


# =============================================================================
# MODIFY:  Compute facility *density* (per 1,000 km^2) instead of raw count.
#
# Hint:
#   counties_pip <- counties_pip |>
#     mutate(
#       area_km2 = as.numeric(units::set_units(st_area(geometry), "km^2")),
#       facility_density = n_facilities / area_km2 * 1000
#     )
#
# Then re-do the ggplot with `aes(fill = facility_density)`.
# =============================================================================


counties_density_pip <- counties_pip |>
  mutate(
    area_km2 = as.numeric(units::set_units(st_area(geometry), "km^2")),
    facility_density = n_facilities / area_km2 * 100
  )
p <- ggplot(counties_density_pip) +
  geom_sf(aes(fill = facility_density), color = "white", linewidth = 0.1) +
  scale_fill_viridis_c(name = "Facilities per 100km2", option = "magma", trans = "sqrt") +
  labs(title = "Powerplant facilities per 100km2") +
  theme_void() +
  theme(legend.position = "right")

print(p)
ggsave("outputs/maps/facility_density_per_county.png", plot = p, width = 10, height = 6, dpi = 150)
