# Function to display the main menu
function Show-MainMenu {
    param (
        [string]$Title = 'System Maintenance Toolkit'
    )
    Clear-Host
    Write-Host "========== $Title =========="
    Write-Host "1: Run System Monitoring FIRST, then Maintenance"
    Write-Host "2: Run System Maintenance FIRST, then Monitoring"
    Write-Host "3: Run Monitoring Only"
    Write-Host "4: Run Maintenance Only"
    Write-Host "Q: Quit"
}

# Function to monitor system resources
function Monitor-SystemResources {
    Write-Output "`n=== Monitoring System Resources ==="

    # Ensure Logs directory exists
    if (!(Test-Path "C:\Logs")) {
        New-Item -ItemType Directory -Path "C:\Logs" | Out-Null
    }

    $logFile = "C:\Logs\system_monitor.txt"
    New-Item -Path $logFile -ItemType File -Force | Out-Null

    # Get total RAM
    $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum

    # Infinite monitoring loop
    while ($true) {
        try {
            # Get system info
            $date = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
            $cpuTime = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            $availMem = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue

            # Format log entry
            $logEntry = "$date > CPU: $($cpuTime.ToString('#,0.000'))%, Avail. Mem.: $($availMem.ToString('N0'))MB (" + ((104857600 * $availMem / $totalRam).ToString("#,0.0")) + "%)"

            # Print to console
            Write-Host $logEntry

            # Append to log file
            $logEntry | Out-File -Append -FilePath $logFile

            # Sleep for 2 seconds before next check
            Start-Sleep -Seconds 2
        } catch {
            Write-Output "Error occurred during monitoring: $_"
            break
        }
    }
}

# Function to perform system maintenance
function Perform-SystemMaintenance {
    # 1. Clean Temporary Files
    function Clean-TempFiles {
        Write-Output "`n=== Cleaning Temporary Files ==="

        $tempFolders = @(
            "$env:TEMP\*",
            "$env:WINDIR\Temp\*",
            "$env:LOCALAPPDATA\Temp\*",
            "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\*",
            "$env:USERPROFILE\Downloads\*"
        )

        foreach ($folder in $tempFolders) {
            try {
                Remove-Item -Path $folder -Force -Recurse -ErrorAction SilentlyContinue
                Write-Output "Cleaned: $folder"
            } catch {
                Write-Output "Failed to clean: $folder"
            }
        }

        # Clear recycle bin
        try {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Output "Recycle Bin emptied"
        } catch {
            Write-Output "Failed to empty Recycle Bin"
        }
    }

    # 2. Restart Critical Services
    function Restart-SystemServices {
        Write-Output "`n=== Restarting Services ==="

        $services = @("Winmgmt", "Dnscache", "Sysmain")

        foreach ($service in $services) {
            try {
                Restart-Service -Name $service -Force
                Write-Output "Restarted: $service"
            } catch {
                Write-Output "Failed to restart: $service"
            }
        }
    }

    # 3. Check for Windows Updates
    function Check-Updates {
        Write-Output "`n=== Checking for Windows Updates ==="

        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0")

            if ($searchResult.Updates.Count -gt 0) {
                Write-Output "Updates available: $($searchResult.Updates.Count)"
                Write-Output "Run Windows Update to install them"
            } else {
                Write-Output "No updates available"
            }
        } catch {
            Write-Output "Could not check for updates (run as Administrator?)"
        }
    }

    # 4. Disk Cleanup
    function Invoke-DiskCleanup {
        Write-Output "`n=== Running Disk Cleanup ==="

        try {
            cleanmgr /sagerun:1 | Out-Null
            Write-Output "Disk cleanup initiated"
        } catch {
            Write-Output "Disk cleanup failed"
        }
    }

    # Main execution
    Clear-Host
    Write-Output "=== System Optimization Started ==="

    Clean-TempFiles
    Restart-SystemServices
    Invoke-DiskCleanup
    Check-Updates

    Write-Output "`n=== Optimization Complete ==="
}

# Main menu logic
do {
    Show-MainMenu
    $selection = Read-Host "`nPlease make a selection"
    switch ($selection) {
        '1' {
            Monitor-SystemResources
            Perform-SystemMaintenance
            Read-Host "`nPress Enter to continue"
        }
        '2' {
            Perform-SystemMaintenance
            Monitor-SystemResources
            Read-Host "`nPress Enter to continue"
        }
        '3' {
            Monitor-SystemResources
            Read-Host "`nPress Enter to continue"
        }
        '4' {
            Perform-SystemMaintenance
            Read-Host "`nPress Enter to continue"
        }
        'Q' {
            Write-Output "Exiting the script. Goodbye!"
            break
        }
        default {
            Write-Output "Invalid selection. Please try again."
        }
    }
} until ($selection -eq 'Q')
