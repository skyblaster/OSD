<#
.SYNOPSIS
Returns a Intel Display Driver Object

.DESCRIPTION
Returns a Intel Display Driver Object

.LINK
#>
function Get-CloudDriverIntelGraphics {
    [CmdletBinding()]
    param (
        [ValidateSet('x64','x86')]
        [string]$CompatArch,
        [ValidateSet('Win7','Win10')]
        [string]$CompatOS
    )
    #=================================================
    #   Uri
    #=================================================
    $Uri = 'https://www.intel.com/content/www/us/en/download/19344/intel-graphics-windows-dch-drivers.html'
    #=================================================
    #   Import Base Catalog
    #=================================================
    $OfflineCloudDriver = Get-Content -Path "$($MyInvocation.MyCommand.Module.ModuleBase)\CloudDriver\CloudDriverIntelGraphics.json" -Raw | ConvertFrom-Json
    #=================================================
    #   Filter
    #=================================================
    switch ($CompatArch) {
        'x64'   {$OfflineCloudDriver = $OfflineCloudDriver | Where-Object {$_.OSArch -match 'x64'}}
        'x86'   {$OfflineCloudDriver = $OfflineCloudDriver | Where-Object {$_.OSArch -match 'x86'}}
    }
    switch ($CompatOS) {
        'Win7'   {$OfflineCloudDriver = $OfflineCloudDriver | Where-Object {$_.OsVersion -match '6.0'}}
        'Win8'   {$OfflineCloudDriver = $OfflineCloudDriver | Where-Object {$_.OsVersion -match '6.3'}}
        'Win10'   {$OfflineCloudDriver = $OfflineCloudDriver | Where-Object {$_.OsVersion -match '10.0'}}
    }
    #=================================================
    #   Online
    #=================================================
    $IsOnline = Test-WebConnection $Uri

    if ($IsOnline) {
        Write-Verbose "Catalog is Online"
        #=================================================
        #   ForEach
        #=================================================
        $ZipFileResults = @()
        $CloudDriver = @()
        $CloudDriver = foreach ($OfflineCloudDriverItem in $OfflineCloudDriver) {
            Write-Verbose "DriverGrouping: $($OfflineCloudDriverItem.DriverGrouping)"
            Write-Verbose "OsArch: $($OfflineCloudDriverItem.OsArch)"
            Write-Verbose "DriverInfo: $($OfflineCloudDriverItem.DriverInfo)"
            #=================================================
            #   WebRequest
            #=================================================
            $DriverInfoWebRequest = Invoke-WebRequest -Uri $OfflineCloudDriverItem.DriverInfo -Method Get -Verbose
            $DriverInfoWebRequestContent = $DriverInfoWebRequest.Content
            $DriverInfoHTML = $DriverInfoWebRequest.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
            $DriverInfoHEAD = $DriverInfoHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
            $DriverInfoMETA = $DriverInfoHEAD.childNodes | Where-Object {$_.nodename -like "meta*"} | Select-Object -Property Name, Content
            #=================================================
            #   Driver Filter
            #=================================================
            $ZipFileResults = @($DriverInfoWebRequestContent -split " " -split '"' -match 'http' -match "downloadmirror" -match ".zip")

            if ($OfflineCloudDriverItem.OsArch -match 'x64') {
                $ZipFileResults = $ZipFileResults | Where-Object {$_ -notmatch 'win32'}
            }
            if ($OfflineCloudDriverItem.OsArch -match 'x86') {
                $ZipFileResults = $ZipFileResults | Where-Object {$_ -notmatch 'win64'}
            }
            $ZipFileResults = $ZipFileResults | Select-Object -Unique
            #=================================================
            #   Driver Details
            #=================================================
            foreach ($DriverZipFile in $ZipFileResults) {
                Write-Verbose "Zip File: $DriverZipFile"
                #=================================================
                #   Defaults
                #=================================================
                $OSDVersion = $(Get-Module -Name OSD | Sort-Object Version | Select-Object Version -Last 1).Version
                $LastUpdate = [datetime] $(Get-Date)
                $OSDStatus = $null
                $OSDGroup = 'IntelDisplay'
                $OSDType = 'Driver'

                $DriverName = $null
                $DriverVersion = $null
                $DriverReleaseId = $null
                $DriverGrouping = $null

                $OperatingSystem = @()
                $OsVersion = $OfflineCloudDriverItem.OsVersion
                $OsArch = $OfflineCloudDriverItem.OsArch
                $OsBuildMax = @()
                $OsBuildMin = @()
        
                $Make = @()
                $MakeNe = @()
                $MakeLike = @()
                $MakeNotLike = @()
                $MakeMatch = @()
                $MakeNotMatch = @('Microsoft')
        
                $Generation = $null
                $SystemFamily = $null
        
                $Model = @()
                $ModelNe = @()
                $ModelLike = @()
                $ModelNotLike = @()
                $ModelMatch = @()
                $ModelNotMatch = @('Surface')
        
                $SystemSku = @()
                $SystemSkuNe = @()
        
                $DriverBundle = $null
                $DriverWeight = 100
        
                $DownloadFile = $null
                $SizeMB = $null
                $DriverUrl = $null
                $DriverInfo = $OfflineCloudDriverItem.DriverInfo
                $DriverDescription = $null
                $Hash = $null
                $OSDGuid = $(New-Guid)
                #=================================================
                #   LastUpdate
                #=================================================
                #$LastUpdateMeta = $DriverInfoMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                #$LastUpdate = [datetime]::ParseExact($LastUpdateMeta, "MM/dd/yyyy HH:mm:ss", $null)

                $LastUpdateMeta = $DriverInfoMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                Write-Verbose "LastUpdateRaw: $LastUpdateMeta"

                if ($LastUpdateMeta) {
                    $LastUpdateSplit = ($LastUpdateMeta -split (' '))[0]
                    #Write-Verbose "LastUpdateSplit: $LastUpdateSplit"
    
                    $LastUpdate = [datetime]::Parse($LastUpdateSplit)
                    #Write-Verbose "LastUpdate: $LastUpdate"
                }
                #=================================================
                #   DriverVersion
                #=================================================
                $DriverVersion = $DriverInfoMETA | Where-Object {$_.name -eq 'DownloadVersion'} | Select-Object -ExpandProperty Content
                #=================================================
                #   DriverUrl
                #=================================================
                $DriverUrl = $DriverZipFile
                #=================================================
                #   Values
                #=================================================
                $DriverGrouping = $OfflineCloudDriverItem.DriverGrouping
                $DriverName = "$DriverGrouping $OsArch $DriverVersion $OsVersion"
                $DriverDescription = $DriverInfoMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
                $DownloadFile = Split-Path $DriverUrl -Leaf
                $OSDPnpClass = 'Display'
                $OSDPnpClassGuid = '{4D36E968-E325-11CE-BFC1-08002BE10318}'
                #=================================================
                #   Create Object
                #=================================================
                $ObjectProperties = @{
                    OSDVersion              = [string] $OSDVersion
                    LastUpdate              = [datetime] $LastUpdate
                    OSDStatus               = [string] $OSDStatus
                    OSDType                 = [string] $OSDType
                    OSDGroup                = [string] $OSDGroup
        
                    DriverName              = [string] $DriverName
                    DriverVersion           = [string] $DriverVersion
                    DriverReleaseId         = [string] $DriverReleaseID
        
                    OperatingSystem         = [string[]] $OperatingSystem
                    OsVersion               = [string[]] $OsVersion
                    OsArch                  = [string[]] $OsArch
                    OsBuildMax              = [string] $OsBuildMax
                    OsBuildMin              = [string] $OsBuildMin
        
                    Make                    = [string[]] $Make
                    MakeNe                  = [string[]] $MakeNe
                    MakeLike                = [string[]] $MakeLike
                    MakeNotLike             = [string[]] $MakeNotLike
                    MakeMatch               = [string[]] $MakeMatch
                    MakeNotMatch            = [string[]] $MakeNotMatch
        
                    Generation              = [string] $Generation
                    SystemFamily            = [string] $SystemFamily
        
                    Model                   = [string[]] $Model
                    ModelNe                 = [string[]] $ModelNe
                    ModelLike               = [string[]] $ModelLike
                    ModelNotLike            = [string[]] $ModelNotLike
                    ModelMatch              = [string[]] $ModelMatch
                    ModelNotMatch           = [string[]] $ModelNotMatch
        
                    SystemSku               = [string[]] $SystemSku
                    SystemSkuNe             = [string[]] $SystemSkuNe
        
                    SystemFamilyMatch       = [string[]] $SystemFamilyMatch
                    SystemFamilyNotMatch    = [string[]] $SystemFamilyNotMatch
        
                    SystemSkuMatch          = [string[]] $SystemSkuMatch
                    SystemSkuNotMatch       = [string[]] $SystemSkuNotMatch
        
                    DriverGrouping          = [string] $DriverGrouping
                    DriverBundle            = [string] $DriverBundle
                    DriverWeight            = [int] $DriverWeight
        
                    DownloadFile            = [string] $DownloadFile
                    SizeMB                  = [int] $SizeMB
                    DriverUrl               = [string] $DriverUrl
                    DriverInfo              = [string] $DriverInfo
                    DriverDescription       = [string] $DriverDescription
                    Hash                    = [string] $Hash
                    OSDGuid                 = [string] $OSDGuid
        
                    OSDPnpClass             = [string] $OSDPnpClass
                    OSDPnpClassGuid         = [string] $OSDPnpClassGuid
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
        }
    }
    #=================================================
    #   Offline
    #=================================================
    else {
        Write-Verbose "Catalog is Offline"
        $CloudDriver = $OfflineCloudDriver
    }
    #=================================================
    #   Remove Duplicates
    #=================================================
    $CloudDriver = $CloudDriver | Sort-Object DriverUrl -Unique
    #=================================================
    #   Select-Object
    #=================================================
    $CloudDriver = $CloudDriver | Select-Object OSDVersion, LastUpdate, OSDStatus, OSDType, OSDGroup,`
    DriverName, DriverVersion,`
    OsVersion, OsArch, MakeNotMatch, ModelNotMatch,`
    DriverGrouping,`
    DownloadFile, DriverUrl, DriverInfo, DriverDescription,`
    OSDGuid,`
    OSDPnpClass, OSDPnpClassGuid
    #=================================================
    #   Sort-Object
    #=================================================
    $CloudDriver = $CloudDriver | Sort-Object -Property LastUpdate -Descending
    $CloudDriver | ConvertTo-Json | Out-File "$env:TEMP\CloudDriverIntelGraphics.json" -Encoding ascii -Width 2000 -Force
    #=================================================
    #   Return
    #=================================================
    Return $CloudDriver
    #=================================================
}