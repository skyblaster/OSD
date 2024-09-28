﻿function Set-SetupCompleteCreateStart {
    
    $ScriptsPath = "C:\Windows\Setup\Scripts"
    $RunScript = @(@{ Script = "SetupComplete"; BatFile = 'SetupComplete.cmd'; ps1file = 'SetupComplete.ps1';Type = 'Setup'; Path = "$ScriptsPath"})
    $PSFilePath = "$($RunScript.Path)\$($RunScript.ps1File)"

    if (!(Test-Path -Path $ScriptsPath)){
        Set-SetupCompleteInitialize
    }

    Write-Output "Appending $($RunScript.Script) Files"
    Add-Content -path $PSFilePath "Write-Output 'Starting SetupComplete Script Process'"
    Add-Content -path $PSFilePath "Set-ExecutionPolicy RemoteSigned -Force -Scope CurrentUser"
    Add-Content -path $PSFilePath '$StartTime = Get-Date; Write-Host "Start Time: $($StartTime.ToString("hh:mm:ss"))"'
    Add-Content -path $PSFilePath '$ModulePath = (Get-ChildItem -Path "$($Env:ProgramFiles)\WindowsPowerShell\Modules\osd" | Where-Object {$_.Attributes -match "Directory"} | select -Last 1).fullname'
    Add-Content -path $PSFilePath 'import-module "$ModulePath\OSD.psd1" -Force'
    Add-Content -path $PSFilePath "Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_anywhere.psm1')"
    #Add-Content -path $PSFilePath "Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_winpe.psm1')"
    Add-Content -Path $PSFilePath "Start-Sleep -Seconds 10"
    Add-Content -Path $PSFilePath "Start-Transcript -Path 'C:\OSDCloud\Logs\SetupComplete.log' -ErrorAction Ignore"
    Add-Content -Path $PSFilePath "Write-Output 'Setting PowerPlan to High Performance'"
    Add-Content -Path $PSFilePath "powercfg /setactive DED574B5-45A0-4F42-8737-46345C09C238"
    Add-Content -Path $PSFilePath "Write-Output 'Confirming PowerPlan [powercfg /getactivescheme]'"
    Add-Content -Path $PSFilePath "powercfg /getactivescheme"
    Add-Content -Path $PSFilePath "powercfg -x -standby-timeout-ac 0"
    Add-Content -Path $PSFilePath "powercfg -x -standby-timeout-dc 0"
    Add-Content -Path $PSFilePath "powercfg -x -hibernate-timeout-ac 0"
    Add-Content -Path $PSFilePath "powercfg -x -hibernate-timeout-dc 0"
    Add-Content -Path $PSFilePath "Set-PowerSettingSleepAfter -PowerSource AC -Minutes 0"
    Add-Content -Path $PSFilePath "Set-PowerSettingTurnMonitorOffAfter -PowerSource AC -Minutes 0"
    #Add-Content -Path $PSFilePath "Stop-Transcript"
    #Add-Content -Path $PSFilePath "Restart-Computer -Force"
}