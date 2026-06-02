import geopandas as gpd
import rasterio
from rasterstats import zonal_stats
import pandas as pd

# ── paths ──────────────────────────────────────────────────────────────────────
COUNTIES     = "data/us_counties.shp"
POWERPLANTS  = "data/us_powerplants.shp"
PM25_RASTER  = "data/us_pm25.tif"
NEARBY_KM    = 50  # distance threshold for Q2

# ── load data ──────────────────────────────────────────────────────────────────
counties    = gpd.read_file(COUNTIES)
powerplants = gpd.read_file(POWERPLANTS)

# reproject to equal-area CRS for accurate distance / area calculations
EQUAL_AREA = "EPSG:5070"  # Conus Albers
counties    = counties.to_crs(EQUAL_AREA)
powerplants = powerplants.to_crs(EQUAL_AREA)

# ── Q1: plants per county (spatial join) ───────────────────────────────────────
joined = gpd.sjoin(powerplants, counties, how="left", predicate="within")
q1 = joined.groupby("index_right").size().rename("plant_count")
counties = counties.join(q1).fillna({"plant_count": 0})
counties["plant_count"] = counties["plant_count"].astype(int)

# ── Q2: plants within 50 km of each county ─────────────────────────────────────
buffered = counties.copy()
buffered["geometry"] = counties.geometry.buffer(NEARBY_KM * 1000)
nearby = gpd.sjoin(powerplants, buffered[["geometry"]], how="left", predicate="within")
q2 = nearby.groupby("index_right").size().rename("nearby_count")
counties = counties.join(q2).fillna({"nearby_count": 0})
counties["nearby_count"] = counties["nearby_count"].astype(int)

# ── Q3: mean PM2.5 per county ──────────────────────────────────────────────────
with rasterio.open(PM25_RASTER) as src:
    raster_crs = src.crs

counties_raster_crs = counties.to_crs(raster_crs)
stats = zonal_stats(counties_raster_crs, PM25_RASTER, stats=["mean"], nodata=-9999)
counties["mean_pm25"] = [s["mean"] for s in stats]

# ── comparison ─────────────────────────────────────────────────────────────────
def pm25_comparison(counties, count_col, label):
    with_plants    = counties[counties[count_col] > 0]["mean_pm25"].mean()
    without_plants = counties[counties[count_col] == 0]["mean_pm25"].mean()
    print(f"\n[{label}]")
    print(f"  Counties WITH plants:    {with_plants:.2f} µg/m³")
    print(f"  Counties WITHOUT plants: {without_plants:.2f} µg/m³")
    print(f"  Difference:              {with_plants - without_plants:+.2f} µg/m³")
    return {"measure": label, "with_plants": with_plants, "without_plants": without_plants}

rows = [
    pm25_comparison(counties, "plant_count",  "within-county count"),
    pm25_comparison(counties, "nearby_count", f"within {NEARBY_KM} km count"),
]

# ── save outputs ───────────────────────────────────────────────────────────────
counties[["GEOID", "NAME", "plant_count", "nearby_count", "mean_pm25"]].to_csv(
    "outputs/counties_with_stats.csv", index=False
)
pd.DataFrame(rows).to_csv("outputs/pm25_comparison.csv", index=False)
print("\nOutputs written to outputs/")
