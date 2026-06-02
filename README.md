# US Power Plants & PM2.5 Analysis

## Questions
1. How many power plants are in each county?
2. Which counties have a power plant within 25 km?
3. What is each county's mean PM2.5?
4. Does mean PM2.5 differ between counties with and without nearby power plants?

## Data
| File | Source |
|------|--------|
| `us_counties.shp` | US Census TIGER |
| `us_powerplants.shp` | EIA-860 (generators ≥ 1 MW) |
| `us_pm25.tif` | Annual mean PM2.5 surface (~5 km resolution) |

Data files are not tracked in git. Place them in `data/data_afternoon/` before running.

## Scripts

**`01_setup.r`** — Environment setup. Sets the working directory, loads all required packages (`sf`, `terra`, `exactextractr`, `dplyr`, `ggplot2`, etc.), reads the three data files, and reprojects all layers to EPSG:5070 (NAD83 Conus Albers Equal Area) so that distance and area calculations are in meters. Run this first; all other scripts source it.

**`02_overlay_points.r`** — Point-in-polygon overlay. Uses `st_join(..., join = st_within)` to assign each power plant to the county containing it, then aggregates to a count per county (`counties_pip`). Produces a choropleth of raw facility counts. Also computes facility density (plants per 100 km²) to account for county size differences.

**`03_plants_per_county.r`** — Duplicate of the point-in-polygon workflow from script 02, used as a standalone source for `counties_pip` when other scripts need that object directly.

**`04_plants_per_25km.r`** — Buffer + intersect overlay. Buffers each plant point by 25 km using `st_buffer()`, then uses `st_intersects()` to flag every county whose boundary overlaps any buffer (`near_plants`). Also maps the count of plants within 25 km per county. Includes a 1 km buffer variant stored separately as `counties_near_1km` so it does not overwrite the 25 km result.

**`05_mean_PM2.5.r`** — Raster-to-polygon extraction. Uses `exactextractr::exact_extract()` to compute the area-weighted mean PM2.5 for each county. Also computes maximum PM2.5 and the share of each county exceeding the EPA NAAQS threshold of 9 µg/m³. Ends with a comparison of mean PM2.5 between counties with and without power plants, using both the within-county count and the 25 km buffer as the exposure measure.

## Methods
- **CRS:** All vector layers reprojected to EPSG:5070 (Conus Albers Equal Area) for accurate distance and area calculations.
- **Q1/Q3:** Spatial join with `st_within` predicate; plants that fall on county boundaries or coastlines may not match any county (a small gap between total plant count and sum of per-county counts is expected).
- **Q2:** County polygons buffered by 25 km; counties whose boundary intersects any buffer are flagged as "near" a plant. 25 km was chosen because PM2.5 disperses over regional scales — a plant just outside a county border still affects local air quality.
- **Q3:** Area-weighted zonal mean of the PM2.5 raster using `exactextractr`, which weights each raster cell by the fraction of its area inside the county polygon.

## Results

| Measure | Counties WITH plants | Counties WITHOUT plants | Difference |
|---------|---------------------|------------------------|------------|
| Within-county (≥1 plant inside county) | 7.88 µg/m³ (n=2,135) | 7.99 µg/m³ (n=974) | −0.11 |
| Nearby (within 25 km buffer) | 7.92 µg/m³ (n=3,002) | 7.86 µg/m³ (n=107) | +0.06 |

**Interpretation:** Neither measure shows a meaningful difference in PM2.5 between counties with and without power plants — the gaps are under 0.15 µg/m³ in both cases. The direction weakly reverses between the two measures: the within-county comparison suggests plant-hosting counties have slightly *lower* PM2.5, while the nearby measure shows slightly *higher* PM2.5 near plants. Notably, only 107 of ~3,100 counties are more than 25 km from any plant, so the 25 km measure has very little "unexposed" group to compare against.

## How to Run

Open R with the project root as your working directory, then source the scripts in order:

```r
source("scripts/01_setup.r")
source("scripts/02_overlay_points.r")
source("scripts/04_plants_per_25km.r")
source("scripts/05_mean_PM2.5.r")
```
