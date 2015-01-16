# Extract ZIP file to folder
function Expand-ZIPFile($file, $destination)
{
    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}

# Create a shortcut to an executable
function Save-Shortcut($sourceExe, $destinationPath)
{
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($destinationPath)
    $Shortcut.TargetPath = $sourceExe
    $Shortcut.Save()
}

# Set ACLs (with inheritance)
#
# This function does not recurse since it is assumed that the folder is empty.
# If some subfolder has explicit "no inheritance" flags, the FullControl control 
# type might not apply.
function Set-FullPermission($folder)
{
    # Make sure $folder is a directory
    if (! ((Get-Item $folder) -is [System.IO.DirectoryInfo]))
    { 
        Write-Host "$folder is not a valid directory."
        Write-Host "Skipping"
        return;
    }

    # Get the ACLs for $folder
    $acl = Get-Acl $folder

    # Access rule
    $AccessRule= New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", `
        "FullControl", "ContainerInherit, Objectinherit", "InheritOnly", "Allow")

    # Set access sule
    $acl.SetAccessRule($accessRule)
    $acl | Set-Acl $folder
}

# Uninstall Datamover JSL as a Windows Service
function Remove-DatamoverJSL($datamoverJSLPath, $platformNBits)
{
    # Configuration file
    $JSL_INI = $datamoverJSLPath + "\" + "jsl_static.ini"

    # Uninstalling Datamover JSL as a Windows Service
    if ($platformNBits -eq 64)
    {
        # Executable
        $JSL_EXE = $datamoverJSLPath + "\" + "jsl_static64.exe"
    }
    else
    {
        # Executable
        $JSL_EXE = $datamoverJSLPath + "\" + "jsl_static.exe"
    }

    & $JSL_EXE -remove $JSL_INI
}

# Install Datamover JSL as a Windows Service
function Install-DatamoverJSL($datamoverJSLPath, $platformNBits)
{
    # Configuration file
    $JSL_INI = $datamoverJSLPath + "\" + "jsl_static.ini"

    # Installing Datamover JSL as a Windows Service
    if ($platformNBits -eq 64)
    {
        # Executable
        $JSL_EXE = $datamoverJSLPath + "\" + "jsl_static64.exe"
    }
    else
    {
        # Executable
        $JSL_EXE = $datamoverJSLPath + "\" + "jsl_static.exe"
    }

    & $JSL_EXE -install $JSL_INI
}
