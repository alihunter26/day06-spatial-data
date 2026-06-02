# US Power Plants & PM2.5 Analysis

## Questions
1. How many power plants are in each county?
2. How many plants are within 50 km of each county?
3. What is each county's mean PM2.5?

**Comparison:** Mean PM2.5 in counties with vs. without power plants, using both the within-county and 50 km measures.

## Data
| File | Source |
|------|--------|
| `us_counties.shp` | US Census TIGER |
| `us_powerplants.shp` | EIA-860 (generators ≥ 1 MW) |
| `us_pm25.tif` | Annual mean PM2.5 surface (~5 km resolution) |

Data files are not tracked in git. Place them in `data/` before running.

## Methods
- **CRS:** All vector layers reprojected to EPSG:5070 (Conus Albers Equal Area) for accurate distance and area calculations.
- **Q1:** Spatial join (within predicate) of power plants to counties, then grouped count.
- **Q2:** County polygons buffered by 50 km; plants falling inside the buffer are counted as "nearby." 50 km was chosen because PM2.5 disperses over regional scales — a plant just outside a county border still affects local air quality — while remaining small enough to exclude truly distant facilities.
- **Q3:** Zonal statistics (mean) of the PM2.5 raster over each county polygon using `rasterstats`.

## Results

*(Fill in after running `analysis.py`)*

| Measure | Counties WITH plants | Counties WITHOUT plants | Difference |
|---------|---------------------|------------------------|------------|
| Within-county count | — | — | — |
| Within 50 km count  | — | — | — |

**Interpretation:** *(write after running)*

## Outputs
- `outputs/counties_with_stats.csv` — per-county plant count, nearby count, mean PM2.5
- `outputs/pm25_comparison.csv` — summary comparison table

## How to Run
```bash
pip install geopandas rasterio rasterstats pandas
python analysis.py
```
