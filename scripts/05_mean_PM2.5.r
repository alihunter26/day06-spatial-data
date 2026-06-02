# =============================================================================
# 04_mean_PM2.5.r
# OVERLAY 3: Raster -> Polygon
#
# Question: What is the mean PM2.5 in each county?
# Uses exactextractr::exact_extract -- area-weighted aggregation.
# =============================================================================

# Set your working directory in 01_setup.R, then run this script.
source("scripts/01_setup.R")

# ---- Approach B: exact_extract (recommended) --------------------------------
# Area-weights each cell by the share of its area inside the polygon.
# Works directly on sf objects.

counties_pm_exact <- counties |>
  mutate(
    mean_pm25_exact = exact_extract(pm25, geometry,
      fun = "mean",
      progress = FALSE
    )
  )


# ---- Plot ------------------------------------------------------
quartz()
print(
  ggplot(counties_pm_exact) +
    geom_sf(aes(fill = mean_pm25_exact), color = NA) +
    scale_fill_viridis_c(name = "PM2.5", option = "magma") +
    labs(title = "Mean PM2.5 by county (area-weighted)") +
    theme_void()
)


# =============================================================================
# MODIFY 1:  Compute the *maximum* PM2.5 per county.
#            Use fun = "max" in exact_extract().
#
# MODIFY 2:  Compute the share of each county where PM2.5 > 9 ug/m^3
#            (the new EPA NAAQS).
#
#   counties_share <- counties |>
#     mutate(
#       share_above_9 = exact_extract(
#         pm25, geometry,
#         fun = function(values, weights) {
#           sum(weights[!is.na(values) & values > 9]) /
#             sum(weights[!is.na(values)])
#         }
#       )
#     )
#
#   ggplot(counties_share) +
#     geom_sf(aes(fill = share_above_9), color = NA) +
#     scale_fill_viridis_c(name = "Share > 9", option = "magma") +
#     theme_void()
# =============================================================================



# 1)

counties_max_pm_exact <- counties |>
  mutate(
    max_pm25_exact = exact_extract(pm25, geometry,
      fun = "max",
      progress = FALSE
    ),
    max_above_9 = max_pm25_exact > 9
  )

quartz()
print(
  ggplot(counties_max_pm_exact) +
    geom_sf(aes(fill = max_pm25_exact), color = NA) +
    scale_fill_viridis_c(
      name = "PM2.5", option = "magma"
    ) +
    labs(title = "exact_extract (area-weighted)") +
    theme_void()
)
# 2)

counties_share <- counties |>
  mutate(
    share_above_9 = exact_extract(
      pm25, geometry,
      fun = function(values, weights) {
        sum(weights[!is.na(values) & values > 9]) /
          sum(weights[!is.na(values)])
      }
    )
  )

ggplot(counties_share) +
  geom_sf(aes(fill = share_above_9), color = NA) +
  scale_fill_viridis_c(name = "Share > 9", option = "magma") +
  theme_void()

# 3)

print(
  ggplot(counties_max_pm_exact) +
    geom_sf(aes(fill = max_above_9), color = "white", linewidth = 0.1) +
    scale_fill_manual(
      name   = "Max > 9?",
      values = c(`TRUE` = "#E57200", `FALSE` = "#E5E5E5")
    ) +
    labs(title = "Counties whose maximum PM2.5 exceeds 9 ug/m^3") +
    theme_void()
)

counties_pm_exact <- counties_pm_exact |>
  mutate(
    mean_above_9 = mean_pm25_exact > 9
  )

print(
  ggplot(counties_pm_exact) +
    geom_sf(aes(fill = mean_above_9), color = "white", linewidth = 0.1) +
    scale_fill_manual(
      name   = "Mean > 9?",
      values = c(`TRUE` = "#E57200", `FALSE` = "#E5E5E5")
    ) +
    labs(title = "Counties whose maximum PM2.5 exceeds 9 ug/m^3") +
    theme_void()
)

counties_pm_exact <- counties_pm_exact |>
  mutate(
    mean_above_12 = mean_pm25_exact > 12
  )


print(
  ggplot(counties_pm_exact) +
    geom_sf(aes(fill = mean_above_12), color = "white", linewidth = 0.1) +
    scale_fill_manual(
      name   = "Mean > 12?",
      values = c(`TRUE` = "#E57200", `FALSE` = "#E5E5E5")
    ) +
    labs(title = "Counties whose maximum PM2.5 exceeds 12 ug/m^3") +
    theme_void()
)


# =============================================================================
# COMPARE: Mean PM2.5 in counties with vs. without power plants
# =============================================================================

counties_combined <- counties_pm_exact |>
  st_drop_geometry() |>
  select(GEOID, mean_pm25_exact) |>
  left_join(
    st_drop_geometry(counties_pip) |> select(GEOID, n_facilities),
    by = "GEOID"
  ) |>
  left_join(
    st_drop_geometry(counties_near) |> select(GEOID, near_plants),
    by = "GEOID"
  ) |>
  mutate(has_plant = n_facilities > 0)

cat("\n--- Within-county measure ---\n")
print(
  counties_combined |>
    group_by(has_plant) |>
    summarize(n_counties = n(), mean_pm25 = mean(mean_pm25_exact, na.rm = TRUE))
)

cat("\n--- Nearby measure (25 km buffer) ---\n")
print(
  counties_combined |>
    group_by(near_plants) |>
    summarize(n_counties = n(), mean_pm25 = mean(mean_pm25_exact, na.rm = TRUE))
)
