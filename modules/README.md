# AQAMKDevOpsPS - PowerShell DevOps Module

A comprehensive PowerShell module designed for automating deployment and management tasks for SMK (Script Marking) applications, including XML configuration management, Windows service operations, and IIS administration.

## Overview

This module provides a collection of PowerShell functions to support DevOps operations for the SMK/GS (GenScan) application suite. It includes utilities for XML file manipulation, Windows service management, IIS configuration, and Windows feature management.

## Features

### XML Configuration Management

- **Set-XMLFileAttr**: Modify XML attribute values using XPath expressions
- **Get-XMLFileAttr**: Retrieve XML attribute values
- **Set-XML**: Update XML node values with custom XPath queries

### Windows Service Management

- **Get-ServiceComponentObject**: Find Windows services by name or display name
- **Get-ServiceExePath**: Extract executable paths from service objects
- **Uninstall-SISImporterService**: Safely stop and uninstall SIS Importer services
- **New-SISImporterService**: Install new SIS Importer Windows services

### IIS Management

- **Application Pool Operations**:

  - `New-IISApplicationPool`: Create new application pools
  - `Set-IISApplicationPoolSettings`: Configure runtime version, pipeline mode, periodic restart, and identity
  - `Get-IISApplicationPoolConfig`: Retrieve current application pool settings
  - `Test-forIISApplicationPool`: Check if application pool exists

- **Website Operations**:

  - `New-IISWebsite`: Create new IIS websites with bindings
  - `Set-IISWebsite`: Modify existing website configuration
  - `Get-IISWebites`: List all IIS websites
  - `Test-forIISWebSite`: Check if website exists

- **Application Operations**:
  - `New-IISApplication`: Create applications under websites
  - `Set-IISApplication`: Modify application settings
  - `Test-forIISApplication`: Check if application exists

### Windows Feature Management

- **Test-forWindowsFeature**: Check if Windows features are installed
- **Install-WinFeature**: Install Windows features (supports both Workstation and Server)
- **Get-OsType**: Determine the operating system type

### Deployment Utilities

- **New-Release**: Extract and organize release packages from zip files

## Installation

1. Copy the `AQAMKDevOpsPS-dev.psm1` file to your PowerShell modules directory
2. Import the module:

```powershell
Import-Module AQAMKDevOpsPS-dev
```

## Usage Examples

### XML Configuration

```powershell
# Update database connection string
Set-XMLFileAttr -targetDirectory "C:\Config" -fileName "config.xml" `
    -parentNode "ScanStats" -node "keyword" `
    -attKeyName "name" -attKeyValue "Server" `
    -attValueName "value" -attValueValue "NEWSERVER.DOMAIN.COM"
```

### Service Management

```powershell
# Find and restart a service
$service = Get-ServiceComponentObject -service "ScannedBoxImporter"
if ($service) {
    Uninstall-SISImporterService -ComponentObject $service
    New-SISImporterService -EnvAndInstanceNumber "GS-Dev-1" `
        -ScannedBoxImporterRootPath "C:\Services" -gsVersion "20250723.1"
}
```

### IIS Configuration

```powershell
# Create application pool with custom settings
New-IISApplicationPool -appPoolName "MyAppPool" -appcmdPath "C:\Windows\System32\inetsrv\appcmd.exe"
Set-IISApplicationPoolSettings -appPoolName "MyAppPool" `
    -appcmdPath "C:\Windows\System32\inetsrv\appcmd.exe" `
    -managedRuntimeVersion "v4.0" -managedPipelineMode "Integrated"

# Create website
New-IISWebsite -siteName "MyApp" -siteHostName "myapp.local" `
    -physicalPath "C:\inetpub\myapp" -portBindings "80" `
    -appcmdPath "C:\Windows\System32\inetsrv\appcmd.exe"
```

## Requirements

- **PowerShell 7.1** or higher
- **Administrative privileges** for IIS and Windows service operations
- **IIS Management Tools** installed for IIS-related functions
- **Windows Server 2019 +** or **Windows 11** with appropriate features enabled

## Dependencies

- Built-in PowerShell modules: `Microsoft.PowerShell.Management`
- Windows Features: IIS, .NET Framework
- External tools: `appcmd.exe` for IIS management

## File Structure

```
GS/
├── modules/
│   └── AQAMKDevOpsPS-dev.psm1
├── scripts/
│   └── deployment/
│       └── deploy-service.ps1
└── deployment-GSdbInstance.yaml
```

## Azure DevOps Integration

This module is designed to work with Azure DevOps pipelines. See `deployment-GSdbInstance.yaml` for example pipeline configuration that uses these functions for automated deployments.

## Contributing

When adding new functions, please include:

- Complete help blocks with Synopsis, Description, Parameters, Examples, and Notes
- Error handling with try/catch blocks
- Parameter validation where appropriate
- Consistent naming conventions

## License

Internal use for SMK/GS application deployment and management.

## Support

For issues or questions, please refer to the internal documentation wiki or contact the DevOps team.
