# PowerModelsMCDC.jl changelog

All notable changes to PowerModelsMCDC.jl will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Some lookup tables were not defined in `add_ref_dcgrid!` for AC-only grids

## [0.1.1] - 2024-01-09

### Added

- This changelog
- Multiconductor status parameters for `convdc` and `branchdc` components

### Fixed

- Missing constraints in DCP formulation
- Some `convdc` parameters were not converted to multiconductor
- Set conductor specific start values for dc bus voltage variables

## [0.1.0] - 2023-07-15

Initial release.
Includes OPF probem for HVDC networks, with multiconductor model of the DC grid.

[unreleased]: https://github.com/Electa-Git/PowerModelsMCDC.jl/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/Electa-Git/PowerModelsMCDC.jl/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Electa-Git/PowerModelsMCDC.jl/releases/tag/v0.1.0
