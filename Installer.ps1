# openBISImporterToolset (oBIT) installer
#
# This requires Windows Management Framework 4.0 and Windows > XP 
# http://www.microsoft.com/en-us/download/details.aspx?id=40855
#
# Copyright 2015 Aaron Ponti, Single Cell Unit, D-BSSE, ETH Zurich (Basel)

# Import requirements
. "$PSScriptRoot\lib\settings.ps1"
. "$PSScriptRoot\lib\util.ps1"
. "$PSScriptRoot\lib\conf.ps1"

# ===========================================================================================
#
# Greetings
#
# ===========================================================================================

clear
Write-Host "openBIS Importer Toolset (oBIT) Installer"
Write-Host "Copyright (c) 2015, Aaron Ponti, D-BSSE ETHZ Basel"
Write-Host ""

# ===========================================================================================
#
# INITIAL CHECKS
#
# ===========================================================================================

# Make sure the script is being run by an administrator
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [System.Security.Principal.WindowsPrincipal] $identity
$role = [System.Security.Principal.WindowsBuiltInRole] "Administrator"
if(-not $principal.IsInRole($role))
{
    Write-Host "This script must be run from an elevated shell."
    exit 1
}

# ===========================================================================================
#
# PLATFORM INFORMATION
#
# ===========================================================================================

# Get OS version and architecture
$OS_VERSION = [System.Environment]::OSVersion.Version.Major
if ($OS_VERSION -lt 6)
{
    Write-Host "This script supports Windows 7 and above."
    exit 1
}
$PLATFORM_N_BITS = (Get-WmiObject -Class Win32_Processor).addresswidth

# ===========================================================================================
#
# USER INPUT
#
# Remark: to hide passwods, use $pass = Read-Host 'What is your password?' -AsSecureString
#
# ===========================================================================================

# Installation directory

Write-Host "--- INSTALLATION DIRECTORY ---"
Write-Host ""
Write-Host "This is the installation directory for oBIT. All components will be installed here."
Write-Host ""

$DEFAULT_INSTALL_DIR = "C:\oBIT"
$INSTALL_DIR = Read-Host "Installation directory [$DEFAULT_INSTALL_DIR]"
if ($INSTALL_DIR.Equals(""))
{
    $INSTALL_DIR = $DEFAULT_INSTALL_DIR
}

# Create the folder if it does not exist
if(!(Test-Path -Path $INSTALL_DIR )){
   New-Item -ItemType directory -Path $INSTALL_DIR | Out-Null
}

# The installation directory must be empty
$INSTALL_DIR_INFO = Get-ChildItem -force $INSTALL_DIR | Measure-Object
if ($INSTALL_DIR_INFO.count -gt 0)
{
    Write-Host "Sorry, the installation directory must be empty!"
    exit 1
}

Write-Host "" 
Write-Host "--- JAVA RUNTIME ---"
Write-Host ""

# Use system-wide Java?
$DEFAULT_SYSTEM_JAVA = "N"
Write-Host "If you have an existing Java 7 installation, you can use that. Otherwise, the JRE will be downloaded and installed in $INSTALL_DIR (default)."
$SYSTEM_JAVA = Read-Host "Use existing Java installation (y/n) [$DEFAULT_SYSTEM_JAVA]"
if ($SYSTEM_JAVA.Equals(""))
{
    $SYSTEM_JAVA = $DEFAULT_SYSTEM_JAVA

    # Inform the user
    Write-Host ""
    Write-Host "In order to download the Java Runtime, you have to accept the Oracle license (please see http://www.oracle.com/technetwork/java/javase/terms/license/index.html)."
    $ACCEPT_JAVA_LICENSE = Read-Host "Accept Oracle license? (y/n) [Y]"
    if ($ACCEPT_JAVA_LICENSE.Equals(""))
    {
        $ACCEPT_JAVA_LICENSE = "Y"
    }
    if ( -not $ACCEPT_JAVA_LICENSE.toUpper().Equals("Y"))
    {
        Write-Host "Exiting now."
        exit 0
    }

    # JAVA path
    $FINAL_JRE_PATH = $INSTALL_DIR + "\jre"

}
$SYSTEM_JAVA = $SYSTEM_JAVA.ToUpper()
if ($SYSTEM_JAVA.Equals("Y"))
{
    # Ask for the jre path
    $DEFAULT_FINAL_JRE_PATH = "C:\Program Files\Java\jre7"
    if (Test-Path $DEFAULT_FINAL_JRE_PATH)
    {
        $FINAL_JRE_PATH = Read-Host "Please specify the full path to the jre folder [$DEFAULT_FINAL_JRE_PATH]"
        if ($FINAL_JRE_PATH.Equals(""))
        {
            $FINAL_JRE_PATH = $DEFAULT_FINAL_JRE_PATH
        }
    }
    else
    {
        $FINAL_JRE_PATH = Read-Host "Please specify the full path to the jre folder"
    }
    
    # Check the selection
    if (!(Test-Path $FINAL_JRE_PATH))
    {
        Write-Host "The selected path does not exist."
        exit 1
    }

}
if ($SYSTEM_JAVA -ne "Y" -and $SYSTEM_JAVA -ne "N")
{
    Write-Host "Invalid answer."
    exit 1
}

# ===========================================================================================
#
# oBIT CONFIGURATION
#
# ===========================================================================================

# oBIT configuration

Write-Host ""
Write-Host "--- oBIT CONFIGURATION ---"
Write-Host ""
Write-Host "To configure the various components of oBIT you will now be asked to provide some information."

#
# Check that drive D exists:
#
# $driveCheck = Get-PSDrive | Where-Object { $_.Name -match "D" } | Select-Object name
#

# Annotation Tool user folder
Write-Host ""
$DEFAULT_USER_FOLDER = "D:\toOpenBIS"
$USER_FOLDER = Read-Host "Annotation Tool user folder [$DEFAULT_USER_FOLDER]"
if ($USER_FOLDER.Equals(""))
{
    $USER_FOLDER = $DEFAULT_USER_FOLDER
}
if(!(Test-Path -Path $USER_FOLDER )){
   New-Item -ItemType directory -Path $USER_FOLDER | Out-Null
}

# Datamover data folder
Write-Host ""
$DEFAULT_DATAMOVER_DATA_FOLDER = "D:\Datamover"
$DATAMOVER_DATA_FOLDER = Read-Host "Datamover data folder [$DEFAULT_DATAMOVER_DATA_FOLDER]"
if ($DATAMOVER_DATA_FOLDER.Equals(""))
{
    $DATAMOVER_DATA_FOLDER = $DEFAULT_DATAMOVER_DATA_FOLDER
}
if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER )){
   New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER | Out-Null
}

# Subfolders
$DATAMOVER_DATA_FOLDER_INCOMING = $DATAMOVER_DATA_FOLDER + "\incoming"
$DATAMOVER_DATA_FOLDER_BUFFER   = $DATAMOVER_DATA_FOLDER + "\buffer"
$DATAMOVER_DATA_FOLDER_MANUAL   = $DATAMOVER_DATA_FOLDER + "\manual_intervention"

if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_INCOMING )){
   New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER_INCOMING | Out-Null
}
if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_BUFFER )){
   New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER_BUFFER | Out-Null
}
if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_MANUAL )){
   New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER_MANUAL | Out-Null
}

# Local user to run the Datamover JSL Windows service
Write-Host ""
$DEFAULT_LOCAL_USER = "openbis"
$LOCAL_USER = Read-Host "Local user to run Datamover JSL (Windows service) [$DEFAULT_LOCAL_USER]"
if ($LOCAL_USER.Equals(""))
{
    $LOCAL_USER = $DEFAULT_LOCAL_USER
}

# Remote Datastore server user: by default, set it to the same as the local user.
Write-Host ""
$DEFAULT_REMOTE_USER = $LOCAL_USER
$REMOTE_USER = Read-Host "Remote user to login to the DataStore Server [$DEFAULT_REMOTE_USER]"
if ($REMOTE_USER.Equals(""))
{
    $REMOTE_USER = $DEFAULT_REMOTE_USER
}

# Remote Datastore server user: by default, set it to the same as the local user.
Write-Host ""
$REMOTE_HOST = Read-Host "DataStore Server host"
if ($REMOTE_HOST.Equals(""))
{
    # TODO: Ask again
    Write-Host "You must specify the remote host!"
    exit 1
}

# Remote Datastore server port (can be omitted)
Write-Host ""
$REMOTE_PORT = Read-Host "DataStore Server port (optional)"

# Remote dropbox folder on the DataStore server
Write-Host ""
$DEFAULT_REMOTE_PATH = "/local0/openbis/openbis/data/incoming-microscopy"
$REMOTE_PATH = Read-Host "Full path to the dropbox folder on the DataStore Server [$DEFAULT_REMOTE_PATH]"
if ($REMOTE_PATH.Equals(""))
{
    $REMOTE_PATH = $DEFAULT_REMOTE_PATH
}

# Path to the 'lastchanged' executable of Datamover on the DataStore server
$REMOTE_LASTCHANGED_PATH = Read-Host "Full path to the 'lastchanged' executable of Datamover on the DataStore server (optional)"

# Annotation Tool admin: acquisition type
Write-Host ""
Write-Host "Select the acquisition station or type the Annotation Tool is going to manage:"
Write-Host "    [1] $ANNOTATION_TOOL_STATION_TYPES_OPTION_1"
Write-Host "    [2] $ANNOTATION_TOOL_STATION_TYPES_OPTION_2"
$selectedStationOption = Read-Host "Your choice"
If ($selectedStationOption -eq 1)
{
    $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = $ANNOTATION_TOOL_STATION_TYPES_OPTION_1
}
elseif ($selectedStationOption -eq 2)
{
    $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = $ANNOTATION_TOOL_STATION_TYPES_OPTION_2
}
else
{
    # TODO: Ask again
    Write-Host "Invalid choice!"
    exit 1 
}

# Annotation Tool admin: self-signed SSL certificates
Write-Host ""
Write-Host "Depending on how openBIS was installed, you might need to force accepting self-signed certificates for the Annotation Tool to be able to login from the acquisition station."
$ACCEPT_SELF_SIGNED_CERTIFICATES = Read-Host "Accept self-signed certificates? (y/n) [N]"
if ($ACCEPT_SELF_SIGNED_CERTIFICATES.Equals(""))
{
    $ACCEPT_SELF_SIGNED_CERTIFICATES = "N"
}
$ACCEPT_SELF_SIGNED_CERTIFICATES = $ACCEPT_SELF_SIGNED_CERTIFICATES.ToUpper()
if ($ACCEPT_SELF_SIGNED_CERTIFICATES.Equals("Y"))
{
    $ACCEPT_SELF_SIGNED_CERTIFICATES = "yes"
}
elseif ($ACCEPT_SELF_SIGNED_CERTIFICATES.Equals("N"))
{
    $ACCEPT_SELF_SIGNED_CERTIFICATES = "no"
}
else
{
    Write-Host "Invalid choice!"
    exit 1
}

# Inform the user that questions are over
Write-Host ""
Write-Host ""
Write-Host "Thank you! Now relax while the openBIS Importer Toolset is installed and configured."

# ===========================================================================================
#
# DOWNLOAD
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- DOWNLOADING PACKAGES ---"
Write-Host ""

# Get Datamover JSL
Write-Host -NoNewline "Downloading Datamover JSL... "
Invoke-WebRequest $DATAMOVER_JSL_URL -OutFile $DATAMOVER_JSL_OUTFILE
Write-Host "Completed."

# Get Datamover
Write-Host -NoNewline "Downloading Datamover... "
Invoke-WebRequest $DATAMOVER_URL -OutFile $DATAMOVER_OUTFILE
Write-Host "Completed."

# Get the Annotation Tool
Write-Host -NoNewline "Downloading Annotation Tool... "
Invoke-WebRequest $OBIT_ANNOTATION_TOOL_URL -OutFile $OBIT_ANNOTATION_TOOL_OUTFILE
Write-Host "Completed."

# Get Java (using cygwin wget)
if ($SYSTEM_JAVA.Equals("N"))
{
    Write-Host -NoNewline "Downloading JAVA... "
    & $WGET_EXE -P $INSTALL_DIR --quiet --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $JAVA_URL
    Write-Host "Completed."
}

# ===========================================================================================
#
# EXTRACT
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- EXTRACTING PACKAGES ---"
Write-Host ""

# Extract Datamover JSL
Write-Host -NoNewline "Extracting Datamover JSL... "
Expand-ZIPFile –File $DATAMOVER_JSL_OUTFILE –Destination $INSTALL_DIR
Rename-Item $INSTALL_DIR\obit_datamover_jsl-$DATAMOVER_JSL_VERSION $INSTALL_DIR\obit_datamover_jsl
Write-Host "Completed."

# Extract Datamover
Write-Host -NoNewline "Extracting Datamover... "
Remove-Item -recurse $INSTALL_DIR\obit_datamover_jsl\datamover
Expand-ZIPFile –File $DATAMOVER_OUTFILE –Destination $INSTALL_DIR\obit_datamover_jsl
Move-Item $INSTALL_DIR\obit_datamover_jsl\datamover\etc\service.properties $INSTALL_DIR\obit_datamover_jsl\datamover\etc\service.properties_sample

# Copy the scripts folder for the right platform
New-Item -ItemType directory -Path $INSTALL_DIR\obit_datamover_jsl\datamover\scripts | Out-Null
$source = $INSTALL_DIR + "\obit_datamover_jsl\scripts\dist\" + $PLATFORM_N_BITS + "bit\*"
Copy-Item -Recurse $source $INSTALL_DIR\obit_datamover_jsl\datamover\scripts

# Create the home and .ssh folders for the local user
$sshFolder = $INSTALL_DIR + "\obit_datamover_jsl\datamover\bin\home\" + $LOCAL_USER + "\.ssh"
New-Item -ItemType directory -Path $sshFolder | Out-Null
Write-Host "Completed."

# TODO: Create the home directory for the local user and set up ssh
Write-Host ""
Write-Host "TODO: Create the home directory for the local user and set up ssh."
Write-Host ""

# Extract the Annotation Tool
Write-Host -NoNewline "Extracting Annotation Tool... "
Expand-ZIPFile –File $OBIT_ANNOTATION_TOOL_OUTFILE –Destination $INSTALL_DIR
Write-Host "Completed."

# Extract Java
if ($SYSTEM_JAVA.Equals("N"))
{
    # From the 64 server version, we copy just the jre subfolder.
    Write-Host -NoNewline "Extracting Java... "
    cd $INSTALL_DIR
    if ($PLATFORM_N_BITS -eq 64)
    {
        New-Item -ItemType directory -Path $INSTALL_DIR\jdk | Out-Null
        & $TAR_EXE -zxf $JAVA_FILENAME -C jdk --strip-components=1
        Move-Item $INSTALL_DIR\jdk\jre $INSTALL_DIR
        Remove-Item -recurse $INSTALL_DIR\jdk
        Remove-Item $INSTALL_DIR\$JAVA_FILENAME
    }
    else
    {
        New-Item -ItemType directory -Path $INSTALL_DIR\jre
        & $TAR_EXE -zxf $JAVA_FILENAME -C jre --strip-components=1
        Remove-Item $INSTALL_DIR\$JAVA_FILENAME
    }
    Write-Host "Completed."
    cd $PSScriptRoot
}

# ===========================================================================================
#
# Write all configuration files
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- CONFIGURING PACKAGES ---"
Write-Host ""

# Configure the Annotation Tool (user + admin)
Write-Host -NoNewline "Configuring the Annotation Tool... "
$OBIT_ANNOTATION_TOOL_PATH = $INSTALL_DIR + "\obit_annotation_tool"
Configure-AnnotationTool -AnnotationToolPath $OBIT_ANNOTATION_TOOL_PATH -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS
Write-Host "Completed."

# Configure Datamover
Write-Host -NoNewline "Configuring Datamover... "
$DATAMOVER_PATH = $INSTALL_DIR + "\obit_datamover_jsl\datamover"

Configure-Datamover -DatamoverPath $DATAMOVER_PATH -DatamoverDataIncomingPath $DATAMOVER_DATA_FOLDER_INCOMING `
    -DatamoverDataBufferPath $DATAMOVER_DATA_FOLDER_BUFFER -DatamoverDataManualPath $DATAMOVER_DATA_FOLDER_MANUAL `
    -RemoteUser $REMOTE_USER -RemoteHost $REMOTE_HOST -RemotePort $REMOTE_PORT -RemotePath $REMOTE_PATH `
    -RemoteLastChangedPath $REMOTE_LASTCHANGED_PATH -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS

$sshFolder = $INSTALL_DIR + "\obit_datamover_jsl\datamover\bin\home\" + $LOCAL_USER + "\.ssh"
Write-SSH-Information -SshFolder $sshFolder -RemoteHost $REMOTE_HOST -RemoteUser $REMOTE_USER

Write-Host "Completed."

# Configure Datamover JSL Windows service
Write-Host "Configuring Datamover JSL Windows service..."
$DATAMOVER_JSL_PATH = $INSTALL_DIR + "\obit_datamover_jsl"
Configure-Datamover_JSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -LocalUser $LOCAL_USER -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS
Write-Host "Completed"

# Set up the aquisition station (i.e. create an Annotation Tool Admin XML settings file)
Write-Host "Setting up acquisition station..."
Create-AnnotationTool-Settings -UserFolder $USER_FOLDER -RemoteHost $REMOTE_HOST -RemotePort $REMOTE_PORT `
    -DatamoverDataIncomingPath $DATAMOVER_DATA_FOLDER_INCOMING -AnnotationToolAdminAcqType $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE `
    -AcceptSelfSignedCertificates $ACCEPT_SELF_SIGNED_CERTIFICATES
Write-Host "Completed"

# Completed
Write-Host "" 
Write-Host "All done!" 
exit 0
