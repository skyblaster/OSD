function Set-HyperVName {
    [CmdletBinding()]
    param ()
    $HyperVName = Get-HyperVName
    Write-Output "Renaming Computer to $HyperVName"
    Rename-Computer -NewName $HyperVName -Force 
}