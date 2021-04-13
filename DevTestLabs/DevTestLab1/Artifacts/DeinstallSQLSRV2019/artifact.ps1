###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = 'Stop'

# Suppress progress bar output.
$ProgressPreference = 'SilentlyContinue'

# Ensure we force use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $Error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "`nERROR: $message" -ForegroundColor Red
    }

    Write-Host "`nThe artifact failed to apply.`n"

    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################
#
# Functions used in this script.

# Function to install the package
function Deinstall-SqlSrv
{
    [CmdletBinding()]
    param
    (
        [String]
        $ConfigurationFile
    )

    $FilePath = "C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\SQL2019\setup.exe"
    $Path = "C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\SQL2019\"

    #/ConfigurationFile=ConfigurationFile.ini"
    # Copy File to setup working dir.
    Copy-Item -Path $ConfigurationFile -Destination $Path

    
    # Call the SQL Server setup.exe with a configuration file that run silently
    Invoke-Process -FilePath $FilePath -ArgumentList "/ConfigurationFile=ConfigurationFile.ini"
}

# Function to start a process
function Invoke-Process
{
    param
    (
        [String]
        $FilePath = $(throw "The FileName must be provided."),
        [String]
        $ArgumentList = ''
    )

    # Prepare specifics for starting the process that will install the component.
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.Arguments = $ArgumentList
    $startInfo.CreateNoWindow = $true
    $startInfo.ErrorDialog = $false
    $startInfo.FileName = $FilePath
    $startInfo.RedirectStandardError = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $startInfo.WorkingDirectory = $wd

    # Initialize a new process.
    $process = New-Object System.Diagnostics.Process
    try
    {
        # Configure the process so we can capture all its output.
        $process.EnableRaisingEvents = $true
        # Hook into the standard output and error stream events
        $errEvent = Register-ObjectEvent -SourceIdentifier OnErrorDataReceived $process "ErrorDataReceived" `
            `
            {
                param
                (
                    [System.Object] $sender,
                    [System.Diagnostics.DataReceivedEventArgs] $e
                )
                foreach ($s in $e.Data) { if ($s) { Write-Host "$s" -ForegroundColor Red -NoNewline } }
            }
        $outEvent = Register-ObjectEvent -SourceIdentifier OnOutputDataReceived $process "OutputDataReceived" `
            `
            {
                param
                (
                    [System.Object] $sender,
                    [System.Diagnostics.DataReceivedEventArgs] $e
                )
                foreach ($s in $e.Data) { if ($s) { Write-Host "$s" -NoNewline } }
            }
        $process.StartInfo = $startInfo;
        Write-Host "Executing $FilePath $ArgumentList"

        # Attempt to start the process.
        if ($process.Start())
        {
            # Read from all redirected streams before waiting to prevent deadlock.
            $process.BeginErrorReadLine()
            $process.BeginOutputReadLine()
            # Wait for the application to exit for no more than 15 minutes.
            $process.WaitForExit(900000) | Out-Null
        }

        # Determine if process failed to execute.
        if ($process.ExitCode -eq 3010)
        {
            Write-Host 'The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.'
        }
        elseif ($process.ExitCode -eq 2359302)
        {
            # Ignore it as valid, as it means that a patch has already been applied.
        }
        elseif ($process.ExitCode -ne 0)
        {
            # Throwing an exception at this point will stop any subsequent
            # attempts for deployment.
            throw New-Object System.Exception($startInfo.FileName + ' exited with code: ' + $process.ExitCode)
        }
    }
    finally
    {
        # Free all resources associated to the process.
        $process.Close();
        
        # Remove any previous event handlers.
        Unregister-Event OnErrorDataReceived -Force | Out-Null
        Unregister-Event OnOutputDataReceived -Force | Out-Null
    }
}


###################################################################################################
#
# Main execution block.
#


try
{
    # Set the working directory to the location where the script resides
    Push-Location $PSScriptRoot

    # Configuration file
    $ConfigurationFile = "ConfigurationFile.ini"

    # Writ out some message
    Write-Host "Start deinstall process with configuration file $ConfigurationFile."

    # Call the function to install the package 
    Deinstall-SqlSrv -configurationfile $ConfigurationFile

    # Write out success message
    Write-Host "`nThe artifact was applied successfully.`n"
}
finally
{
    # deleting downloaded file
    if ($coreMsi)
    {
        Remove-Item -Path $coreMsi -ErrorAction SilentlyContinue -Force
    }

    # Getting back to the origin location
    Pop-Location
}