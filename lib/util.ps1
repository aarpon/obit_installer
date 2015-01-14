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

# Install Datamover JSL as a Windows Service
function Install-DatamoverJSL()
{
    Write-Host "TO DO!"
}
