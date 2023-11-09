# :arrows_clockwise: VMware SRM As Built Report Changelog

## [0.4.5] - 2023-11-09

### Fixed

- Fix issue where if a protection group was not protecting any VMs, it would list the VMs in the previous protection group in the output. @flynngw

## [0.4.4] - 2023-08-25

### Fixed

- Fix [#23](https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/issues/23)
- Fix product edition health check

## [0.4.3] - 2023-08-23

### Fixed

- Fix in verbose message using a non-existent variable in Get-AbrSRMLicense module. Fix [#19](https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/issues/19)

## [0.4.2] - 2023-05-16

### Changed

- Code cleanup
- Removed unused files
- Modified SRA and Array Manager section for better handling of errors

## [0.4.1] - 2023-05-15

### Added

- Automated tweet release workflow

## [0.4.0] - 2023-05-14

### Added

- Added Array Pairs information @tpcarman
- Added Storage Replication Adapter information @tpcarman

### Changed

- Improved report content and structure @tpcarman
- Improved bug and feature request templates
- Changed Required Modules to AsBuiltReport.Core v1.3.0

## [0.3.1] - 2022-01-17

### Added

- Added Recovery Site PlaceHolder Datastore Information
- Added Vmware Replication VM status (Replicated/Non-Replicated)

### Changed

- Improved Recovery Site SRM status validation.

### Fixed

- Fix per table caption warning message

## [0.3.0] - 2021-12-11

### Added

- Added VM hardware information:
  - vCenter Server Inventory
  - SRM Server Inventory
  - Replication Server Inventory
- Added Function to convert from VIObject to Inventory Mapping

### Changed

- Improved Recovery Site vCenter status validation.
- Improved title structure

### Fixed

- Fixed credential issues. Closes [#4](https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/issues/4)

## [0.2.0] - 2021-11-01

### Added

- Added vCenter Summary.
- Added SRM Summary Information.
  - Added SRM Licensing information.
  - Added SRM ACL Permissions information.
- Added SRM Protection Group Information.
  - Added Protection Group VR & SAN type Information.
  - Added Per VM Protection Properties.
- Added SRM Recovery Plan Information.
  - Added Per VM Recovery Settings.
- Added SRM Inventory Mapping Information.
- Added Protected & Recovery Site Infromation.

### Changed

- Implemented remote validation of vCenter credentials (separate credentials for protected and recovery sites).
- The code was changed to match the new module structure.

## [0.1.0] - 2021-10-16

- Initial release from @mattallford.
