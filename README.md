# obit_installer
The obit_installer downloads, configures and installs all client-side dependences of the openBIS Importer Toolset.

## Notes

Run it from Windows PowerShell (ISE) ad an administrator.

obit_installer requires Windows Management Framework 4.0 and Windows > XP
* http://www.microsoft.com/en-us/download/details.aspx?id=40855

For your convenience, the setup files for Windows 7 32 and 64 bit are in ./deps/.

By default, Windows does not allow running unsigned scripts. If this is the case, run the following
as an administrator in PowerShell:

       Set-ExecutionPolicy RemoteSigned 
