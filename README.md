<!-- ********** DO NOT EDIT THESE LINKS ********** -->
<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a>
            <img src='https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport/master/AsBuiltReport.png' width="8%" height="8%" /></a>
</p>
<p align="center">
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.VMware.SRM/" alt="PowerShell Gallery Version">
        <img src="https://img.shields.io/powershellgallery/v/AsBuiltReport.VMware.SRM.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.VMware.SRM/" alt="PS Gallery Downloads">
        <img src="https://img.shields.io/powershellgallery/dt/AsBuiltReport.VMware.SRM.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.VMware.SRM/" alt="PS Platform">
        <img src="https://img.shields.io/powershellgallery/p/AsBuiltReport.VMware.SRM.svg" /></a>
</p>
<p align="center">
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/graphs/commit-activity" alt="GitHub Last Commit">
        <img src="https://img.shields.io/github/last-commit/AsBuiltReport/AsBuiltReport.VMware.SRM/master.svg" /></a>
    <a href="https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.VMware.SRM/master/LICENSE" alt="GitHub License">
        <img src="https://img.shields.io/github/license/AsBuiltReport/AsBuiltReport.VMware.SRM.svg" /></a>
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/graphs/contributors" alt="GitHub Contributors">
        <img src="https://img.shields.io/github/contributors/AsBuiltReport/AsBuiltReport.VMware.SRM.svg"/></a>
</p>
<p align="center">
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>
<!-- ********** DO NOT EDIT THESE LINKS ********** -->

# VMware SRM As Built Report

VMware SRM As Built Report is a PowerShell module which works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-sourced community project which utilises PowerShell to produce as-built documentation in multiple document formats for multiple vendors and technologies.

Please refer to the AsBuiltReport [website](https://www.asbuiltreport.com) for more detailed information about this project.

# :books: Sample Reports

## Sample Report - Custom Style 1

Sample VMware SRM As Built report HTML file: [Sample VMware SRM As-Built Report.html](https://technomyth.zenprsolutions.net/wp-content/uploads/2022/01/Sample-VMware-SRM-As-Built-Report.html)

# :beginner: Getting Started

Below are the instructions on how to install, configure and generate a VMware SRM As Built report.

## :floppy_disk: Supported Versions
<!-- ********** Update supported SRM versions ********** -->
The VMware SRM As Built Report supports the following SRM versions;

Tested On:

- SRM 8.3
- SRM 8.4
- SRM 8.5

### PowerShell

This report is compatible with the following PowerShell versions;

<!-- ********** Update supported PowerShell versions ********** -->
| Windows PowerShell 5.1 |     PowerShell 7    |
|:----------------------:|:--------------------:|
|   :white_check_mark:   | :white_check_mark: |

## :wrench: System Requirements

<!-- ********** Update system requirements ********** -->
PowerShell 5.1 or PowerShell 7, and the following PowerShell modules are required for generating a VMware SRM As Built report.

- [AsBuiltReport.VMware.SRM Module](https://www.powershellgallery.com/packages/AsBuiltReport.VMware.SRM/).

### Linux & macOS

- .NET Core is required for cover page image support on Linux and macOS operating systems.
  - [Installing .NET Coe.re for macOS](https://docs.microsoft.com/en-us/dotnet/core/install/macos)
  - [Installing .NET Core for Linux](https://docs.microsoft.com/en-us/dotnet/core/install/linux)

❗ If you are unable to install .NET Core, you must set `ShowCoverPageImage` to `False` in the report JSON configuration file.

### :closed_lock_with_key: Required Privileges

Tested with vCenter Global Read-Only permissions.

## :package: Module Installation

### PowerShell

```powershell
install-module AsBuiltReport.VMware.SRM
```

### GitHub

If you are unable to use the PowerShell Gallery, you can still install the module manually. Ensure you repeat the following steps for the [system requirements](https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM#wrench-system-requirements) also.

1. Download the code package / [latest release](https://github.com/AsBuiltReport/AsBuiltReport.VMware.SRM/releases/latest) zip from GitHub
2. Extract the zip file
3. Copy the folder `AsBuiltReport.VMware.SRM` to a path that is set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with

    ```powershell
    $path = (Get-Module -Name AsBuiltReport.VMware.SRM -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```

5. Close and reopen the PowerShell terminal window.

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable PSModulePath if you want to use another path._

## :pencil2: Configuration

The VMware SRM As Built Report utilises a JSON file to allow configuration of report information, options, detail and healthchecks.

A VMware SRM report configuration file can be generated by executing the following command;

```powershell
New-AsBuiltReportConfig -Report VMware.SRM -FolderPath <User specified folder> -Filename <Optional>
```

Executing this command will copy the default VMware SRM report JSON configuration to a user specified folder.

All report settings can then be configured via the JSON file.

The following provides information of how to configure each schema within the report's JSON file.

<!-- ********** DO NOT CHANGE THE REPORT SCHEMA SETTINGS ********** -->
### Report

The **Report** schema provides configuration of the VMware SRM report information.

| Sub-Schema          | Setting      | Default                        | Description                                                  |
|---------------------|--------------|--------------------------------|--------------------------------------------------------------|
| Name                | User defined | VMware SRM As Built Report | The name of the As Built Report                              |
| Version             | User defined | 1.0                            | The report version                                           |
| Status              | User defined | Released                       | The report release status                                    |
| ShowCoverPageImage  | true / false | true                           | Toggle to enable/disable the display of the cover page image |
| ShowTableOfContents | true / false | true                           | Toggle to enable/disable table of contents                   |
| ShowHeaderFooter    | true / false | true                           | Toggle to enable/disable document headers & footers          |
| ShowTableCaptions   | true / false | true                           | Toggle to enable/disable table captions/numbering            |

### Options

The **Options** schema allows certain options within the report to be toggled on or off.

| Sub-Schema      | Setting      | Default | Description                                                                                                                                                                                 |
|-----------------|--------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ShowDefinitionInfo | true / false | false    | Toggle to enable/disable VMware SRM Section Documentation

<!-- ********** Add/Remove the number of InfoLevels as required ********** -->
### InfoLevel

The **InfoLevel** schema allows configuration of each section of the report at a granular level. The following sections can be set.

There are 4 levels (0-3) of detail granularity for each section as follows;

| Setting | InfoLevel         | Description                                                                                                                                |
|:-------:|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
|    0    | Disabled          | Does not collect or display any information                                                                                                |
|    1    | Enabled / Summary | Provides summarised information for a collection of objects                                                                                |
|    2    | Adv Summary       | Provides condensed, detailed information for a collection of objects                                                                       |
|    3    | Detailed          | Provides detailed information for individual objects                                                                                       |

The table below outlines the default and maximum **InfoLevel** settings for each section.

| Sub-Schema   | Default Setting | Maximum Setting |
|--------------|:---------------:|:---------------:|
| Summary      |        1        |        1        |
| Protected    |        1        |        1        |
| Recovery     |        1        |        1        |
| ProtectionGroup |        1        |        3        |
| RecoveryPlan |        1        |        3        |
| InventoryMapping     |        1        |        1        |


### Healthcheck

The **Healthcheck** schema is used to toggle health checks on or off.

## :computer: Examples

There are a few examples listed below on running the AsBuiltReport script against a VMware vCenter Server target. Refer to the `README.md` file in the main AsBuiltReport project repository for more examples.

```powershell
# Generate a VMware SRM As Built Report for vCenter Server '192.168.5.16' using specified credentials. Export report to HTML & DOCX formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Jon\Documents'
PS C:\> New-AsBuiltReport -Report VMware.SRM -Target 192.168.5.16 -Username 'administrator@vsphere.local' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -Timestamp

# Generate a VMware SRM As Built Report for vCenter Server 192.168.5.16 using specified credentials and report configuration file. Export report to Text, HTML & DOCX formats. Use default report style. Save reports to 'C:\Users\Jon\Documents'. Display verbose messages to the console.
PS C:\> New-AsBuiltReport -Report VMware.SRM -Target 192.168.5.16 -Username 'administrator@vsphere.local' -Password 'P@ssw0rd' -Format Text,Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -ReportConfigFilePath 'C:\Users\Jon\AsBuiltReport\AsBuiltReport.VMware.SRM.json' -Verbose

# Generate a VMware SRM As Built Report for vCenter Server 192.168.5.16 using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Jon\Documents'.
PS C:\> $Creds = Get-Credential
PS C:\> New-AsBuiltReport -Report VMware.SRM -Target 192.168.5.16 -Credential $Creds -Format Html,Text -OutputFolderPath 'C:\Users\Jon\Documents' -EnableHealthCheck

# Generate a VMware SRM As Built Report for vCenter Server 192.168.5.16 using specified credentials. Export report to HTML & DOCX formats. Use default report style. Reports are saved to the user profile folder by default. Attach and send reports via e-mail.
PS C:\> New-AsBuiltReport -Report VMware.SRM -Target 192.168.5.16 -Username 'administrator@vsphere.local' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -SendEmail
```

## :x: Known Issues

- If the protected and recovery sites are not configured with "Enhanced Linked Mode" and the credentials used are not the same in both sites, it will be required to provide valid remote vCenter credentials.
- In certain occasions there is a noticeable delay while connecting to the remote vCenter.
