# SENSEflux: Spatially Explicit Nutrient Source Estimate and Flux Model

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23501339.svg)](https://doi.org/10.5281/zenodo.23501339)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-blue.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Language: MATLAB](https://img.shields.io/badge/Language-MATLAB-orange.svg)](https://www.mathworks.com/products/matlab.html)

**SENSEflux** is a spatially explicit, process-informed statistical and mass-balance modeling framework developed by the [MSU Hydrogeology Lab](https://www.msu.edu/~kendal30/) at Michigan State University. 

The model simulates the fate, attenuation, and transport of **Total Nitrogen (TN)** and **Total Phosphorus (TP)** from point and nonpoint landscape sources through river networks to receiving lakes, wetlands, and coastal waters.

---

## Model Components

SENSEflux tracks nutrient dynamics across four interconnected stages:

1. **Landscape Nutrient Applications:** Spatially explicit input layers representing fertilizer, manure, atmospheric deposition, point sources, and septic systems.
2. **In Situ Losses:** Immediate terrestrial and agricultural retention/losses prior to hydrological mobilization.
3. **Basin Attenuation & Hydrological Pathways:** Nutrient routing and attenuation partitioned across distinct physical pathways, specifically highlighting overland flow, shallow subsurface routing, and artificial agricultural tile drainage networks.
4. **Aquatic Attenuation:** In-stream and in-lake nutrient retention and decay as water flows through the river network.

---

## Repository Structure

```text
SENSEflux/
├── Model/                        # Core model simulation & calibration scripts
│   ├── Stats_model_master_TN_Annual_2023.mlx  # Master workflow for Total Nitrogen (Live Script)
│   ├── Stats_model_master_TP_Annual_2023.mlx  # Master workflow for Total Phosphorus (Live Script)
│   ├── init_stats_model_2023.m   # Parameter and array initialization
│   ├── optim_stats_model_2023.m  # Optimization objective functions
│   └── optim_wrapper_2023.m      # Calibration wrapper routines
├── Inputs/                       # Data formatting and pre-processing
│   ├── TN_Annual_Save_Mat.mlx    # Compiles raw input rasters into structured TN matrices
│   └── TP_Annual_Save_Mat.mlx    # Compiles raw input rasters into structured TP matrices
├── Helper/                       # Geospatial and utility functions
│   ├── extend_domain.m           # Spatial domain extension utilities
│   ├── trim_domain.m             # Spatial domain masking/clipping utilities
│   ├── import_grid.m             # Raster grid ingest
│   ├── unit_conversions.m        # Mass/flux and geographic unit conversions
│   └── gdal/                     # Geospatial data abstraction library bindings
├── addpath_recurse.m             # Utility to add repository tree to MATLAB path
└── CITATION.cff                  # Machine-readable citation metadata
```

---

## Getting Started

### Prerequisites
* **MATLAB** (R2020a or newer recommended)
* *Optimization Toolbox*
* *Statistics and Machine Learning Toolbox*

### Quick Start
1. Clone the repository:
   ```bash
   git clone https://github.com/MSUHydrogeology/SENSEflux.git
   ```
2. Open MATLAB and set your current folder to the cloned `SENSEflux` directory.
3. Add all project functions and helpers to your MATLAB search path:
   ```matlab
   addpath_recurse('.');
   ```
4. Run either master model workflow located in `Model/`:
   * Open and run `Model/Stats_model_master_TN_Annual_2023.mlx` for **Total Nitrogen**.
   * Open and run `Model/Stats_model_master_TP_Annual_2023.mlx` for **Total Phosphorus**.

---

## Data Availability

Input datasets and model output loads for the U.S. Great Lakes Basin (USGLB) are archived on HydroShare:

* **SENSEflux-USGLB Loads, Sources, and Pathways:**  
  Wan, L., Kendall, A. D., Martin, S. L., Hamlin, Q. F., & Hyndman, D. W. (2023). *HydroShare*, [https://doi.org/10.4211/hs.2ec257d6ed0246098d1d6dae8074ecbc](https://doi.org/10.4211/hs.2ec257d6ed0246098d1d6dae8074ecbc)
* **SENSEmap-USGLB Nitrogen and Phosphorus Inputs:**  
  Hamlin, Q. F., Kendall, A. D., Martin, S. L., Whitenack, H. D., Roush, J. A., Hannah, B. A., & Hyndman, D. W. (2020). *HydroShare*, [https://doi.org/10.4211/hs.1a116e5460e24177999c7bd6f8292421](https://doi.org/10.4211/hs.1a116e5460e24177999c7bd6f8292421)

---

## Citation

If you use the SENSEflux model or code in your research, please cite both the primary journal article and the software archive:

### 1. Primary Scientific Publication
> Wan, L., Kendall, A. D., Martin, S. L., Hamlin, Q. F., & Hyndman, D. W. (2023). **Important Role of Overland Flows and Tile Field Pathways in Nutrient Transport**. *Environmental Science & Technology*, 57(46), 17855–17865. [https://doi.org/10.1021/acs.est.3c03741](https://doi.org/10.1021/acs.est.3c03741)

```bibtex
@article{wan2023important,
  author    = {Wan, Luwen and Kendall, Anthony D. and Martin, Sherry L. and Hamlin, Quercus F. and Hyndman, David W.},
  title     = {Important Role of Overland Flows and Tile Field Pathways in Nutrient Transport},
  journal   = {Environmental Science \& Technology},
  volume    = {57},
  number    = {46},
  pages     = {17855--17865},
  year      = {2023},
  publisher = {American Chemical Society},
  doi       = {10.1021/acs.est.3c03741},
  url       = {https://doi.org/10.1021/acs.est.3c03741}
}
```

### 2. Software Archive (Zenodo)
> Wan, L., Kendall, A., Martin, S., Hamlin, Q., & Hyndman, D. (2026). **Spatially Explicit Nutrient Source Estimate Flux (SENSEflux) Model** (Version ES&T_Version). Zenodo. [https://doi.org/10.5281/zenodo.23501339](https://doi.org/10.5281/zenodo.23501339)

```bibtex
@software{wan_senseflux_2026,
  author       = {Wan, Luwen and Kendall, Anthony and Martin, Sherry and Hamlin, Quercus and Hyndman, David},
  title        = {Spatially Explicit Nutrient Source Estimate Flux (SENSEflux) Model},
  year         = {2026},
  publisher    = {Zenodo},
  version      = {ES\&T\_Version},
  doi          = {10.5281/zenodo.23501339},
  url          = {https://doi.org/10.5281/zenodo.23501339}
}
```

---

## Related Publications

* **Martin, S. L., Hamlin, Q. F., Kendall, A. D., Wan, L., & Hyndman, D. W. (2021).** The land use legacy effect: looking back to see a path forward to improve management. *Environmental Research Letters*, 16(3), 035005. [https://doi.org/10.1088/1748-9326/abe14c](https://doi.org/10.1088/1748-9326/abe14c)
* **Hamlin, Q. F., Kendall, A. D., Martin, S. L., Whitenack, H. D., Roush, J. A., Hannah, B. A., & Hyndman, D. W. (2020).** Quantifying Landscape Nutrient Inputs With Spatially Explicit Nutrient Source Estimate Maps. *Journal of Geophysical Research: Biogeosciences*, 125(2), e2019JG005134. [https://doi.org/10.1029/2019jg005134](https://doi.org/10.1029/2019jg005134)
* **Luscz, E. C., Kendall, A. D., & Hyndman, D. W. (2017).** A spatially explicit statistical model to quantify nutrient sources, pathways, and delivery at the regional scale. *Biogeochemistry*, 133(1), 37–57. [https://doi.org/10.1007/s10533-017-0305-1](https://doi.org/10.1007/s10533-017-0305-1)
* **Luscz, E. C., Kendall, A. D., & Hyndman, D. W. (2015).** High resolution spatially explicit nutrient source models for the Lower Peninsula of Michigan. *Journal of Great Lakes Research*, 41(2), 618–629. [https://doi.org/10.1016/j.jglr.2015.02.004](https://doi.org/10.1016/j.jglr.2015.02.004)

---

## License

This project is licensed under the [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/) license.
