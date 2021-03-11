<#
.SYNOPSIS
Allows you to execute a PowerShell Script as a URL Link

.DESCRIPTION
Allows you to execute a PowerShell Script as a URL Link

.PARAMETER Url
The URL of the PowerShell Script to execute.  Redirects are not allowed

.LINK
https://osd.osdeploy.com/module/functions/general/invoke-urlexpression

.NOTES
21.3.8  Initial Release
#>
function Invoke-UrlExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Url
    )
    $Global:UrlExpression = $null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $WebClient = New-Object System.Net.WebClient
    $Global:UrlExpression = $WebClient.DownloadString("$Url")
    $WebClient.Dispose()
    
    Try {
        Invoke-Expression -Command $Global:UrlExpression -ErrorAction Stop
    }
    Catch {
        Write-Warning "Could not connect to Url"
        Write-Warning $Global:UrlExpression
    }
}