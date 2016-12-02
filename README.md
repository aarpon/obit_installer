# openBIS Importer Toolset :: Installer

The openBIS Importer toolset is a tightly integrated collection of tools that allows for the semi-automated, semi-unsupervised registration of annotated datasets into openBIS directly from the acquisition stations.

The oBIT installer downloads, configures and installs all client-side dependences of the openBIS Importer Toolset.

## Instructions

Run `obit_installer.ps1` from Windows PowerShell (ISE) ad an administrator.

### Dependences

obit_installer requires Windows Management Framework 4.0, Microsoft .NET Framework 4.5 and Windows > XP.
* http://www.microsoft.com/en-us/download/details.aspx?id=40855
* https://www.microsoft.com/en-us/download/details.aspx?id=42642

For your convenience, the setup files for Windows 7 32 and 64 bit are in `./deps/`.

### Execution policies

By default, Windows does not allow running unsigned scripts. To run obit_installer, execute the following
as an administrator in PowerShell:

       Set-ExecutionPolicy Unrestricted

After installation, restore the original execution policy as follows:

       Set-ExecutionPolicy Restricted
