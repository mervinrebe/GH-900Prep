#region general Utilties 

function Set-XMLFileAttr {

    <#
    .SYNOPSIS
        Changes values within xml commonly used by SMK applications. 
    .DESCRIPTION
        Note : the terms node and element are often used interchangable, and I have picked up this habit as well. Sorry. 
        The use of empty tags with attribute as the XML structure of the config, webconfig and dbc's files used by Script Marking requires a more involved process to selecting the XML element and modifiy the value. 
        This function is a wrapper around Select-Xml which uses an xpath expression crafted from arguments to select an element using the element name, and an attribute key and its value.Where that set is not uniqine withing the XML, the parent nodes is used as part of the selection filter. 
        Once the element is uniquely identifed, the SetAttriubte method is set the update the attribute value.    
    .NOTES
        Please see wiki for full explaintion, but the following is a guide to identifity elements of XML that corrospond to the arguments required to use this function. 

          <database name="ScanStats">
            <keyword name="Server" value="PRODWBMSQL03.PROD.DRS.LOCAL" />
            <keyword name="Database" value="dclScannerStats" />
        
        If we wish to modify the value of the second line of the xml, we need to provide the argument where

            "ScanStats" is the name of the parent node, and is mapped to the $parentNode argument
            keyword is the name of the node to modifiy and is mapped to the $node argument
            name is the name of the attribute and is mapped to the $attKeyName argument
            "Server" is the value of the name attribute is mapped to $attKeyValue argument
            value is the name of the next attribute and is $attValueName argument
            "PRODWBMSQL03.PROD.DRS.LOCAL" is the value of the value attribute and is mapped to the $attValueValue argument

        While an 'easier' approach would have been to select the element based on a the 'value' attribute, these can change from build to build. So selecting based on attribute 'key' I feel is a better approach and slight more intuitive.
    .LINK
        An excellent and concise explaintion of XML syntax and structure. 
        https://www.stat.auckland.ac.nz/~paul/ItDT/HTML/node46.html#:~:text=The%20main%20content%20of%20an,the%20form%20.

        While centred around html and xpath, this is still a good cheatsheet on xpath 
        https://bugbug.io/blog/testing-frameworks/the-ultimate-xpath-cheat-sheet/
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
       


    param 
    (
        [Parameter(Mandatory)]$targetDirectory,
        [Parameter(Mandatory)]$fileName,
        [Parameter(Mandatory = $false)]$parentNode,
        [Parameter(Mandatory)]$node,
        [Parameter(Mandatory)]$attKeyName,
        [Parameter(Mandatory)]$attKeyValue,
        [Parameter(Mandatory)]$attValueName,
        [Parameter(Mandatory)]$attValueValue
    )

    try {
        $filePath = Get-ChildItem -Path $targetDirectory -Filter $fileName
        $xml = [xml](Get-Content -Path $filePath.FullName)
        
        $targetnode = $xml | Select-XML -XPath "$node[@$attKeyName='$attKeyValue']"
        
        if ($targetnode.Count -gt 1) {
            foreach ($tempNode in $targetnode) {
                if ($tempNode.Node.ParentNode.name -eq $parentNode) {
                    $tempNode.Node.SetAttribute($attValueName, $attValueValue)
                }
            }
        }
        else {
            $targetnode.Node.SetAttribute($attValueName, $attValueValue)
        }
        
        $xml.Save($filePath.FullName)
    }
    catch {
        Write-Error $_
    }
}

function Get-XMLFileAttr {
    param 
    (
        [Parameter(Mandatory)]$targetDirectory,
        [Parameter(Mandatory)]$fileName,
        [Parameter(Mandatory = $false)]$parentNode,
        [Parameter(Mandatory)]$node,
        [Parameter(Mandatory)]$attKeyName,
        [Parameter(Mandatory)]$attKeyValue
    )

    $filePath = Get-ChildItem -Path $targetDirectory -Filter $fileName
    $xml = [xml](Get-Content -Path $filePath.FullName)
    
    $targetnode = $xml | Select-XML -XPath "$node[@$attKeyName='$attKeyValue']"

    if ($targetnode.Count -gt 1) {
        foreach ($tempNode in $targetnode) {
            if ($tempNode.Node.ParentNode.name -eq $parentNode) {
                return $targetnode.Node.value
            }
        }
    }
    else {
        return $targetnode.Node.value
    }      
}

function Set-XML {
    param 
    (
        [Parameter(Mandatory)]$targetDirectory,
        [Parameter(Mandatory)]$fileName,
        [Parameter(Mandatory)]$xmlnode,
        [Parameter(Mandatory)]$attr,
        [Parameter(Mandatory)]$key,
        [Parameter(Mandatory)]$value
    )

    #region iterates through xml tree searching for key and value

    try {
        $filePath = Get-ChildItem -Path $targetDirectory -Filter $fileName
        $xml = [xml](Get-Content -Path $filePath.FullName)
        
        $targetNode = Select-Xml -Xml $xml -XPath $attr

        foreach ($tempNode in $targetNode) {
            if ($tempNode.Node.ParentNode.name -eq $xmlnode) {
                $tempNode.Node.$key = $value
                Write-Host "The new value is $($tempNode.Node.$key)"
            }
        }
        $xml.Save($filePath.FullName)
    }
    catch {
        Write-Error $_
    }

    #endregion
}

function New-Release {
    param
    (
        [Parameter(Mandatory = $false)][string]$sourceDirectory,
        [Parameter(Mandatory = $false)][string]$targetDirectory,
        [Parameter(Mandatory = $false)][string]$versionNumber 
    )

    if (Test-Path -Path (Join-Path $targetDirectory $versionNumber)) {
        Write-Host "Version $versionNumber already in $targetDirectory. Please check and re-run"
        exit
    }

    $zips = Get-ChildItem -Path $sourceDirectory

    foreach ($zip in $zips) {
        New-Item -ItemType Directory -Path (Join-Path -Path $targetDirectory -ChildPath $versionNumber) -Name $zip.BaseName
        Expand-Archive -Path $zip.FullName -DestinationPath (Join-Path $targetDirectory $versionNumber $zip.BaseName)

        if ($zip.BaseName -eq 'dist') {
            $root = (Join-Path $targetDirectory $versionNumber 'dist' 'dist')
            $distFiles = Get-ChildItem -Path $root
        
            foreach ($file in $distFiles) {
                Move-Item -Path $file -Destination (Join-Path $targetDirectory $versionNumber 'dist')
            }
        
            Remove-Item -Path (Join-Path $targetDirectory $versionNumber 'dist' 'dist') -Recurse -force
            Rename-Item -Path (Join-Path $targetDirectory $versionNumber 'dist') -NewName 'ScannedBoxManagmentWebApp'
        }
    }

    $zips | Remove-Item -Force
}

#endregion

#region Win OS

function Test-forWindowsFeature {

    <#
    .SYNOPSIS
        A short one-line action-based description, e.g. 'Tests if a function is valid'
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>

    param
    (
        [string]$featureName,
        [string]$osType
    )

    if ($osType -eq 'WorkStation') {
        $result = Get-WindowsOptionalFeature -Online -FeatureName $featureName
        if ($result.State -eq 'Enabled') {
            return $true
        }
        else {
            return $false
        }
        
    }
    if ($osType -eq 'Server') {
        $result = Get-WindowsFeature -Name $featureName
        if ($result.State -eq 'Installed') {
            return $true
        }
        else {
            return $false
        }
    }
}

function Install-WinFeature {

    <#
    .SYNOPSIS
        A short one-line action-based description, e.g. 'Tests if a function is valid'
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>

    param
    (
        [string]$featureName,
        [string]$osType
    )

    if ($osType -eq 'WorkStation') {
        $result = Enable-WindowsOptionalFeature -Online -FeatureName $featureName
        $installResults = @{
            'Name'            = $featureName
            'Reboot Required' = ($result.RestartNeeded -eq 'Yes') ? $true : $false
        }
        return $installResults    
    }
    if ($osType -eq 'Server') {
        $result = Install-WindowsFeature -name $featureName
        $installResults = @{
            'Name'            = $featureName
            'Reboot Required' = ($result.RestartNeeded -eq 'Yes') ? $true : $false
            'Installed'       = $result.Success
        }
        return $installResults
    }
}

function Get-OsType {
    $osInfo = Get-ComputerInfo
    return $osinfo.OsProductType
}

function Get-ServiceComponentObject {
    <#
    .SYNOPSIS
    Retrieves a Windows service object by service name or display name.
    
    .DESCRIPTION
    Searches for a Windows service using Get-Service where the service name or display name contains the specified service string.
    
    .PARAMETER service
    The service name or part of the service name to search for.
    
    .EXAMPLE
    Get-ServiceComponentObject -service "MyService"
    Returns the service object for any service containing "MyService" in its name or display name.
    
    .OUTPUTS
    System.ServiceController
    Returns the matching service object or null if not found.
    #>
    param 
    (
        [Parameter(Mandatory = $true)][string]$service
    )
    
    try {
        if ($null -cne $service) {
            return Get-Service | Where-Object { $_.Name -like "*$service*" -or $_.DisplayName -like "*$service*" }
        } 
        else {
            Write-Error "Service name '$service' not found or null. Please ensure it is installed and running."
            <# Action when all if and elseif conditions are false #>
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
}

function Get-ServiceExePath {
    <#
    .SYNOPSIS
    Extracts the executable path from a service component object.
    
    .DESCRIPTION
    Parses the BinaryPathName property of a service object to extract the executable path by splitting on quotes and returning the path portion.
    
    .PARAMETER ComponentObject
    The service component object containing the BinaryPathName property.
    
    .EXAMPLE
    $service = Get-Service "MyService"
    Get-ServiceExePath -ComponentObject $service
    Returns the executable path for the specified service.
    
    .OUTPUTS
    System.String
    Returns the file path to the service executable.
    #>
    param 
    (   
        [Parameter(Mandatory = $true)][System.ComponentModel.Component]$ComponentObject
    )
    $servicePath = $ComponentObject.BinaryPathName
    return $servicePath.Split('"')[1]
}

function Uninstall-SISImporterService {
    <#
    .SYNOPSIS
    Uninstalls a SIS Importer Windows service.
    
    .DESCRIPTION
    Stops the specified service if running, then uninstalls it using the service's own uninstall command.
    
    .PARAMETER ComponentObject
    The service component object representing the service to uninstall.
    
    .EXAMPLE
    $service = Get-ServiceComponentObject -service "MyImporter"
    Uninstall-SISImporterService -ComponentObject $service
    Stops and uninstalls the specified importer service.
    
    .NOTES
    The service executable must support the 'uninstall -servicename' command line arguments.
    #>
    param 
    (   
        [Parameter(Mandatory = $true)][System.ComponentModel.Component]$ComponentObject
    )
   
    if ($ComponentObject.Status -ne 'Running') {
        Write-Host "Service $($ComponentObject.Name) is not running. No need to stop it."
    }
    else {
        Stop-Service -Name $ComponentObject.Name
    }

    # Get binary directory path 
    $exePath = Get-ServiceExePath -ComponentObject $ComponentObject


    if (-not (Test-Path $exePath)) {
        Write-Error "Service executable not found at path: $exePath"
        return
    } 
    else {
        # uninstall service
        . $exePath uninstall -servicename $ComponentObject.ServiceName
    }
}

function New-SISImporterService {
    <#
    .SYNOPSIS
    Installs a new SIS Importer Windows service.
    
    .DESCRIPTION
    Creates and installs a new SIS Importer service by navigating to the service directory and executing the install command with the specified service name and display name.
    
    .PARAMETER EnvAndInstanceNumber
    The environment and instance number combination used for the service name and display name.
    
    .PARAMETER ScannedBoxImporterRootPath
    The root directory path where the service files are located.
    
    .PARAMETER gsVersion
    The version number used to locate the specific service directory.
    
    .EXAMPLE
    New-SISImporterService -EnvAndInstanceNumber "GS-ScannedBoxImporter-Dev-3" -ScannedBoxImporterRootPath "C:\Importer" -gsVersion "20250510.1"
    Installs a new SIS Importer service with the specified configuration.
    
    .NOTES
    The service executable (AQA.ScanningIntegrationService.ScannedBoxImport.WindowsService.exe) must exist in the target directory and support install command line arguments.
    Requires the global variables $ScannedBoxImporterImporterName, $ScannedBoxImporterEnvironment, and $ScannedBoxImporterInstanceNumber to be defined.
    #>

    param 
    (
        [Parameter(Mandatory)][string]$importPath,
        [Parameter(Mandatory)][string]$serviceName
    )

    try {
        Set-Location -Path $importPath
        .\AQA.ScanningIntegrationService.ScannedBoxImport.WindowsService.exe install -servicename $serviceName -displayname $serviceName -username $userName -password $password
    }
    catch {
        Write-Error "Failed to create service, please check the path and arguments and try again."
        return  
    } 
}

#endregion 

#region IIS

function Get-IISApplicationPoolConfig {
    <#
        .SYNOPSIS
            Retrieves application pool configurtion infomation.

        .DESCRIPTION
            Retrieves the specfied IIS application pool configurtion infomation and returns setting as key:value hashtable. 
        
        .PARAMETER appPoolName
            The the desired name of the app pool.

        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.

        .PARAMETER managedRuntimeVersion
            A boolean value representing whether or not to retrieve the current configuration value of the Managed Pipeline Mode setting. 
        
        .PARAMETER periodicRestart
            A boolean value representing whether or not to retrieve the current configuration value of the periodic restart setting. 

        .PARAMETER username
            A boolean value representing whether or not to retrieve the current configuration value of the username that the application pool is running as. 

        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISApplicationPool -appPoolName mySiteAppPool -appcmdPath $appcmdPath
            Will result in a in an ppplication pool mySiteAppPool with default settings.
    #>


    param 
    (
        [Parameter(Mandatory = $true)][string]$appPoolName,
        [Parameter(Mandatory = $true)]$appcmdPath,
        [Parameter(Mandatory = $false)][bool]$managedRuntimeVersion,
        [Parameter(Mandatory = $false)][bool]$managedPipelineMode,
        [Parameter(Mandatory = $false)][bool]$periodicRestart,
        [Parameter(Mandatory = $false)][bool]$username
    )

    $query = @{}
    [xml]$appPoolConfig = . $appcmdPath list apppool $appPoolName /config /xml
 
    if ($PSBoundParameters.managedRuntimeVersion -eq $true) {
        try {
            $_managedRuntimeVersion = $appPoolConfig.appcmd.APPPOOL.RuntimeVersion
    
            if ($_managedRuntimeVersion -eq "") {
                $runtimeVersion = "None";
                $query.Add('managedRuntimeVersion', $runtimeVersion)

            }
            else {
                $query.Add('managedRuntimeVersion', $_managedRuntimeVersion )
            }   
        }
        catch {
            Write-Output $_
        }
    }

    if ($PSBoundParameters.managedPipelineMode -eq $true) {
        try {
            $_managedPipelineMode = $appPoolConfig.appcmd.APPPOOL.PipelineMode
            $query.Add('managedPipelineMod', $_managedPipelineMode)
        }
        catch {
            Write-Output $_
        }
    }

    if ($PSBoundParameters.periodicRestart -eq $true) {
        try {
            $_periodicRestart = $appPoolConfig.appcmd.APPPOOL.add.recycling.periodicRestart
            
            if ($_periodicRestart.schedule -eq "") {
                $query.Add('periodicRestart', 'default')
            }
            else {
                $query.Add('periodicRestart', $_periodicRestart.schedule.add.value)
            }

        }
        catch {
            Write-Output $_
        }
    }
    
    if ($PSBoundParameters.username -eq $true) {
        try {
            $_username = $appPoolConfig.appcmd.APPPOOL.add.processModel
            if ($_username.HasAttributes) {
                $query.Add('username', $_username.userName)
            }
            else {
                $query.Add('username', 'default')
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
        }
    }

    return $query
}

function Get-IISWebites {
    <#
        .SYNOPSIS
            Retrieves a list of sites
        
        .DESCRIPTION
            Retrieves a list of IIS sites as an array. 
        
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.

        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.

        .EXAMPLE
        $sites = Get-IISWebites -appcmdPath $appcmdPath
        Will result an array popluated with site names as strings.
    #>

    param 
    (
        [Parameter(Mandatory = $true)]$appcmdPath
    )

    $query = . $appcmdPath list sites /text:name

    return  $query

}

function New-IISApplicationPool {
    <#
        .SYNOPSIS
            Creates a new IIS application pool.
        .DESCRIPTION
            Creates a new IIS application pool with default settings. To be used with Set-IISAppPoolSettings
        
        .PARAMETER appPoolName
            The the desired name of the app pool.

        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISApplicationPool -appPoolName mySiteAppPool -appcmdPath $appcmdPath
            Will result in a in an ppplication pool mySiteAppPool with default settings.
    #>

    [Parameter(Mandatory = $true)]$appPoolName,
    [Parameter(Mandatory = $true)]$appcmdPath

    . $appcmdPath add apppool /name:$appPoolName | Out-Null

}

function New-IISApplication {
    <#
        .SYNOPSIS
            Creates a new IIS application.
            
        .DESCRIPTION
            Creates a new IIS application under site name provided via parameterm or default site if no parameter present.
        
        .PARAMETER siteName
            The name of the site which the application will be created. If not provided, is created under the default site.
        .PARAMETER application
            The subdirectory used to reach application when used with hostname of the site.
        .PARAMETER physicalPath
            The fully qualified path to application files 
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .PARAMETER appPoolName
            The name of the application pool used by the application.

        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISWebsiteApplication -siteName mySite -aliasPath myApplication -physicalPath C:\mysites\myApplication -appcmdPath $appcmdPath -$appPoolName myAppPool
            
            Will result in an application called myApplication which is accessible via mysite/my application using the application pool myAppPool.
    #>

    param
    (
        [Parameter(Mandatory = $true)][string]$siteName,
        [Parameter(Mandatory = $true)][string]$application,
        [Parameter(Mandatory = $true)][string]$physicalPath,
        [Parameter(Mandatory = $true)][string]$appcmdPath,
        [Parameter(Mandatory = $true)][string]$appPoolName
        
    )

    if ($PSBoundParameters.ContainsKey("siteName")) {
        switch ($siteName) {
            'Default' { . $appcmdPath add app /site.name:'Default Web Site' /path:/$application /physicalPath:$physicalPath }
            Default { . $appcmdPath add app /site.name:$siteName /path:/$application /physicalPath:$physicalPath }
        }
    }
      
    if ($PSBoundParameters.ContainsKey("appPoolName")) {
        switch ($siteName) {
            'Default' { . $appcmdPath set app "Default Web Site/$application" /applicationPool:$appPoolName }
            Default { . $appcmdPath set app "$siteName/$application" /applicationPool:$appPoolName }
        }
    }
}

function New-IISWebsite {
    <#
        .SYNOPSIS
            Creates a new IIS site.
            
        .DESCRIPTION
            Creates a new IIS site with name provided with setting provided.
        
        .PARAMETER siteName
            The name of the site which that be created. 
        .PARAMETER siteHostName
            The hostname/URL of the sites binding will be created. 
        .PARAMETER physicalPath
            The fully qualified path to application files.
        .PARAMETER portBindings
            The port number to be used by the site.
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.

        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISWebsiteApplication -siteName mySite -aliasPath myApplication -physicalPath C:\mysites\myApplication -appcmdPath $appcmdPath -$appPoolName myAppPool
            
            Will result in an application called myApplication which is accessible via mysite/my application using the application pool myAppPool.
    #>

    param 
    (
        [Parameter(Mandatory = $true)][string]$siteName,
        [Parameter(Mandatory = $true)][string]$siteHostName,
        [Parameter(Mandatory = $true)][string]$physicalPath,
        [Parameter(Mandatory = $true)][ValidateSet("80", "443")][string]$portBindings,
        [Parameter(Mandatory = $true)][string]$appcmdPath
    )

    switch ($portBindings) {
        "80" { . $appcmdPath add site /name:$siteName /bindings:http://${siteHostName}:$portBindings /physicalPath:$physicalPath }
        "443" { . $appcmdPath add site /name:$siteName /bindings:https://${siteHostName}:$portBindings /physicalPath:$physicalPath }
    }

}

function Set-IISApplication {
    <#
        .SYNOPSIS
            Modifies and exisiting IIS Site application configuration to a value a new.
            
        .DESCRIPTION
            Modifies a IIS application running under a site name with value passed via parameters.
        
        .PARAMETER siteName
            The name of the site which the application is running. If not provided, assumes that site is under the default site.
        .PARAMETER aliasPath
            The subdirectory name used to reach name application, viewed as a subdirectory of the site.
        .PARAMETER physicalPath
            The fully qualified path to the new application files 
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .PARAMETER appPoolName
            The name of the new application pool that you wish to used by the application.

        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
            It is not possible to modify the application name once created. Thus call New-IISWebsiteApplication
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            Set-IISWebsiteApplication -siteName 'Default Web Site' -aliasPath 'api' -appcmdPath $appcmdPath -physicalPath 'C:\sites\api' -appPoolName apiAppPool
            
            Will result in the application called api which is accessible via Default Web Site/api using the application pool myAppPool and it using the files present C:\sites\api
    #>

    param
    (
        [Parameter(Mandatory = $true)][string]$siteName,
        [Parameter(Mandatory = $true)][string]$application,
        [Parameter(Mandatory = $true)][string]$appcmdPath,
        [Parameter(Mandatory = $false)][string]$physicalPath,
        [Parameter(Mandatory = $false)][string]$appPoolName
    )

    if ($PSBoundParameters.ContainsKey("physicalPath")) {
        switch ($siteName) {
            'Default' { . $appcmdPath set vdir "Default Web Site/$application/" /physicalPath:"$physicalPath" }
            Default { . $appcmdPath set vdir "$siteName/$application/" /physicalPath:"$physicalPath" }
        }    
    }
    
    if ($PSBoundParameters.ContainsKey("appPoolName")) {
        switch ($siteName) {
            'Default' { . $appcmdPath set app "Default Web Site/$application" /applicationPool:"$appPoolName" }
            Default { . $appcmdPath set app "$siteName/$application" /applicationPool:"$appPoolName" }
        }
    }
}

function Set-IISApplicationPoolSettings {
    <#
        .SYNOPSIS
            Modifies and exisiting IIS application pool configuration to a new value.
            
        .DESCRIPTION
            Modifies and exisiting IIS application pool configuration to a new value.
        
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .PARAMETER appPoolName
            The name of the new application pool that you wish to used by the application.

        .PARAMETER managedRuntimeVersion
            Sets the Managed Runtime Version os the application pool to the desired value. 
        
        .PARAMETER periodicRestart
            Sets the periodic restart time of the application pool. 

        .PARAMETER username
            Sets the username configuration value of the application pool.
        
        .PARAMETER username
            Sets the password configuration value of the application pool.


        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 

        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            Set-IISWebsiteApplication -siteName 'Default Web Site' -aliasPath 'api' -appcmdPath $appcmdPath -physicalPath 'C:\sites\api' -appPoolName apiAppPool
            
            Will result in the application called api which is accessible via Default Web Site/api using the application pool myAppPool and it using the files present C:\sites\api
    #>

    param 
    (
        [Parameter(Mandatory = $true)][string]$appPoolName,
        [Parameter(Mandatory = $true)]$appcmdPath,
        [Parameter(Mandatory = $false)][ValidateSet("v4.0", "v2.0", "None")][string]$managedRuntimeVersion,
        [Parameter(Mandatory = $false)][ValidateSet("Integrated", "Classic")]$managedPipelineMode,
        [Parameter(Mandatory = $false)][string]$periodicRestart,
        [Parameter(Mandatory = $false)][string]$username, 
        [Parameter(Mandatory = $false)][string]$password
    
    )

    if (Test-forIISApplicationPool -appPoolName $appPoolName -appcmdPath $appcmdPath) {
        Write-Host 'App pool found, updating setting'
        
        if ($PSBoundParameters.ContainsKey("managedRuntimeVersion")) {
            if ($ManagedRuntimeVersion -eq "None") {
                $updatedManagedRuntimeVersion = "";
                . $appcmdPath set apppool /apppool.name:$appPoolName /managedRuntimeVersion:$updatedManagedRuntimeVersion
                Write-Host "Setting runtime to None"
            }
            else {
                . $appcmdPath set apppool /apppool.name:$appPoolName /managedRuntimeVersion:$ManagedRuntimeVersion
                Write-Host "Setting runtime to $ManagedRuntimeVersion"
            }
        }

        if ($PSBoundParameters.ContainsKey("username")) {
            if (!$null -eq $username) {
                . $appcmdPath set apppool /apppool.name:$appPoolName /processModel.identityType:"SpecificUser"
                . $appcmdPath set apppool /apppool.name:$appPoolName /processModel.userName:$username
                . $appcmdPath set apppool /apppool.name:$appPoolName /processModel.password:$password
            } 
            else {
                Write-Host 'No app pool identity provided, using defaults'
            }
        }
     
        if ($PSBoundParameters.ContainsKey("periodicRestart")) {
            . $appcmdPath set apppool /apppool.name:$appPoolName /recycling.periodicRestart.time:00:00:00
            . $appcmdPath set apppool /apppool.name:$appPoolName /+recycling.periodicRestart.schedule.["value='$periodicRestart'"]
        }
    }
    else {
        Write-Host 'App Pool by that name found'
    }
}
function Set-IISWebsite {

    <#
        .SYNOPSIS
            Modifies an exisiting site's configuration to a new value.
            
        .DESCRIPTION
            Modifies an exisiting IIS site configuration to a new value.
            Use when you want to modify the phyical path used by the site, the port binding and the application pool. 

        .PARAMETER siteName
            The fully qualified path to appcmd.exe.
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .PARAMETER physicalPath
            Sets the Managed Runtime Version os the application pool to the desired value. 
        .PARAMETER portBindings
            Sets the periodic restart time of the application pool. 
        .PARAMETER appPoolName
            Sets the username configuration value of the application pool.

        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 

        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            Set-IISWebsiteApplication -siteName 'Default Web Site' -aliasPath 'api' -appcmdPath $appcmdPath -physicalPath 'C:\sites\api' -appPoolName apiAppPool
            
            Will result in the application called api which is accessible via Default Web Site/api using the application pool myAppPool and it using the files present C:\sites\api
    #>

    param 
    (
        [Parameter(Mandatory = $true)][string]$siteName,
        [Parameter(Mandatory = $true)][string]$appcmdPath,
        [Parameter(Mandatory = $false)][string]$physicalPath,
        [Parameter(Mandatory = $false)][string]$siteHostName,
        [Parameter(Mandatory = $false)][ValidateSet("80", "443")][string]$portBindings,
        [Parameter(Mandatory = $false)][string]$appPoolName
    )

    if ($PSBoundParameters.ContainsKey("physicalPath")) {
        . $appcmdPath set vdir "$siteName/" /physicalPath:"$physicalPath"
    }

    switch ($portBindings) {
        "80" { . . $appcmdPath set site /site.name:$siteName /+bindings.[protocol="'http',bindingInformation='*:80:${siteHostName}'"] }
        "443" { . $appcmdPath set site /site.name:$siteName /+bindings.[protocol="'https',bindingInformation='*:443:${siteHostName}'"] }
    }


    if ($PSBoundParameters.ContainsKey("appPoolName")) {
        . $appcmdPath set app "$siteName/" /applicationPool:$appPoolName
    }
}

function Test-forIISAppcmd {
    <#
        .SYNOPSIS
            Test for AppCmd
            
        .DESCRIPTION
            Tests if the appcmd is present in the directory passed as argument. The default directory is 'C:\Windows\System32\inetsrv\appcmd.exe'
        
        .PARAMETER appcmdPath
            The directory to test the presence of appcmd.exe 
        
        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISWebsiteApplication -siteName mySite -aliasPath myApplication -physicalPath C:\mysites\myApplication -appcmdPath $appcmdPath -$appPoolName myAppPool
            
            Will result in an application called myApplication which is accessible via mysite/my application using the application pool myAppPool.
    #>

    param 
    (
        [Parameter(Mandatory = $true)]$appcmdPath
    )

    if (Test-Path -Path $appcmdPath -PathType Container) {
        $appcmdPathFull = $appcmdPath + '\appcmd.exe'

        if (Test-Path($appcmdPathFull)) {
            return $true
        }
        else {
            Write-Host 'appcmd.exe NOT present in directory, please check and re-run'
            return $false
        }
    }
    else {
        if (Test-Path($appcmdPath)) {
            return $true
        }
        else {
            Write-Host 'appcmd.exe NOT present in directory, please check and re-run'
            return $false
        }
    }
}

function Test-forIISApplicationPool {
    <#
        .SYNOPSIS
            Test for Application Pool
            
        .DESCRIPTION
            Tests if the application pool is present in IIS
        
        .PARAMETER appPoolName
            The name of the application pool to test for
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISWebsiteApplication -siteName mySite -aliasPath myApplication -physicalPath C:\mysites\myApplication -appcmdPath $appcmdPath -$appPoolName myAppPool
            
            Will result in an application called myApplication which is accessible via mysite/my application using the application pool myAppPool.
    #>

    param 
    (
        [Parameter(Mandatory = $true)]$appPoolName,
        [Parameter(Mandatory = $true)]$appcmdPath
    )

    $isAppPoolPresent = . $appcmdPath list apppool $appPoolName

    if ($isAppPoolPresent -match $appPoolName) {
        return $true
    }
    else {
        return $false
    }
    
}

function Test-forIISWebSite {
    <#
        .SYNOPSIS
            Test for site 
            
        .DESCRIPTION
            Tests if the site is present in IIS
        
        .PARAMETER appPoolName
            The name of the application pool to test for
        .PARAMETER appcmdPath
            The fully qualified path to appcmd.exe.
        .NOTES
            As with all appcmd.exe cmd or scripts, must be run from admin prompt otherwise unexpected behavior is presented. 
        .LINK
            Specify a URI to a help page, this will show when Get-Help -Online is used.
        .EXAMPLE
            New-IISWebsiteApplication -siteName mySite -aliasPath myApplication -physicalPath C:\mysites\myApplication -appcmdPath $appcmdPath -$appPoolName myAppPool
            
            Will result in an application called myApplication which is accessible via mysite/my application using the application pool myAppPool.
    #>

    param 
    (
        [Parameter(Mandatory = $true)]$siteName,
        [Parameter(Mandatory = $true)]$appcmdPath
    )
    
    $isWebSitePresent = . $appcmdPath list site $siteName

    if ($isWebSitePresent -match $siteName) {
        return $true
    }
    else {
        return $false
    }
    
}

function Test-forIISApplication {

    <#
    .SYNOPSIS
        A short one-line action-based description, e.g. 'Tests if a function is valid'
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    
    

    param 
    (
        [Parameter(Mandatory = $true)]$siteName,
        [Parameter(Mandatory = $true)]$application,
        [Parameter(Mandatory = $true)]$appcmdPath
    )

    $isApplicationPresent = $null

    switch ($siteName) {
        'Default' { $isApplicationPresent = .$appcmdPath list apps /site.name:'Default Web Site' }
        Default { $isApplicationPresent = . $appcmdPath list apps /site.name:$siteName }
    }

    if ($isApplicationPresent -match $application) {
        return $true
    }
    else {
        return $false
    }

}

#endregion