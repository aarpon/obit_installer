# openBISImporterToolset (oBIT) installer
#
# This requires Windows Management Framework 4.0, Microsoft .NET Framework 4.5 and Windows > XP 
#   http://www.microsoft.com/en-us/download/details.aspx?id=40855
#   https://www.microsoft.com/en-us/download/details.aspx?id=42642
#
# For your convenience, the setup files for Windows 7 32 and 64 bit are in ./deps/.
#
# By default, Windows does not allow running unsigned scripts. If this is the case, run the following
# as an administrator in PowerShell:
#
#       Set-ExecutionPolicy Unrestricted 
#
# At the end of the installation, it is recommended to restore the original execution policy:
#
#       Set-ExecutionPolicy Restricted 
#
# Copyright 2015 Aaron Ponti, Single Cell Unit, D-BSSE, ETH Zurich (Basel)

$INSTALLER_VERSION = "0.0.10"

# Add the bin directory to the path
$env:Path = "$PSScriptRoot\bin;" + $env:Path

# Import requirements
. "$PSScriptRoot\lib\util.ps1"
. "$PSScriptRoot\lib\conf.ps1"
. "$PSScriptRoot\lib\user.ps1"

# ===========================================================================================
#
# MACHINE CONSTANTS
#
# ===========================================================================================

$PLATFORM_N_BITS = (Get-WmiObject -Class Win32_Processor).AddressWidth[0]

# ===========================================================================================
#
# GREETINGS
#
# ===========================================================================================

Clear-Host
Write-Host "openBIS Importer Toolset (oBIT) Installer v$INSTALLER_VERSION" -ForegroundColor "cyan"
Write-Host "Copyright (c) 2015 - 2016, Aaron Ponti, D-BSSE ETHZ Basel"
Write-Host ""

# ===========================================================================================
#
# STEP BY STEP GUIDE
#
# ===========================================================================================

Write-Host "--- HOW TO GET HELP ---"
Write-Host ""
Write-Host -NoNewline "For a detailed step-by-step guide, please refer to: "
Write-Host "https://wiki-bsse.ethz.ch/display/oBIT/Automated+oBIT+setup#StepByStep" -ForegroundColor 'green'
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
    Write-Host "This script must be run from an elevated shell. Exiting." -ForegroundColor "red"
    exit 1
}

# Get OS version and architecture
$OS_VERSION = [System.Environment]::OSVersion.Version.Major
if ($OS_VERSION -lt 6)
{
    Write-Host "This script supports Windows 7 and above. Exiting." -ForegroundColor "red"
    exit 1
}

# ===========================================================================================
#
# EXECUTION MODE
#
# ===========================================================================================

Write-Host "--- EXECUTION MODE ---" -ForegroundColor 'cyan'
Write-Host ""
Write-Host "This script can be used to download, install and configure all components of the"
Write-Host "openBIS Importer Toolset on this machine, or it can be used to prepare the setup"
Write-Host "for a target machine that does not have internet connection. The target machine"
Write-Host "can optionally be of different architecture (e.g. 32 instead of 64 bit)."
Write-Host ""

$SETUP_THIS_MACHINE = Read-Host "Do you want to setup oBIT on this machine? (y/n) [Y]"
if ($SETUP_THIS_MACHINE.Equals(""))
{
    $SETUP_THIS_MACHINE = "Y"
}
$SETUP_THIS_MACHINE = $SETUP_THIS_MACHINE.toUpper()
if ($SETUP_THIS_MACHINE.Equals("Y"))
{
    $JUST_DOWNLOAD_PACKAGES = "False"
}
else
{
    $JUST_DOWNLOAD_PACKAGES = "True"

    # Target platform address width
    $USER_PLATFORM_N_BITS = Read-Host "Is the target machine 32 or 64 bit? [$PLATFORM_N_BITS]"
    if ($USER_PLATFORM_N_BITS.Equals(""))
    {
        $USER_PLATFORM_N_BITS = 64
    }
    if (($USER_PLATFORM_N_BITS -ne 32) -and ($USER_PLATFORM_N_BITS -ne 64))
    {
        Write-Host "You must choose either 32 or 64 bits!" -ForegroundColor "red"
        exit 1
    }
    $PLATFORM_N_BITS = $USER_PLATFORM_N_BITS
}

# ===========================================================================================
#
# BUILD ALL URLS AND PATHS FOR THE CHOSEN PLATFORM
#
# ===========================================================================================

. "$PSScriptRoot\lib\urls.ps1"

# ===========================================================================================
#
# USER INPUT
#
# Remark: to hide passwods, use $pass = Read-Host 'What is your password?' -AsSecureString
#
# ===========================================================================================

# Installation directory
Write-Host ""
Write-Host "--- INSTALLATION DIRECTORY ---" -ForegroundColor 'cyan'
Write-Host ""
Write-Host "This is the installation directory for oBIT. All components will be installed here."

$DEFAULT_INSTALL_DIR = "C:\oBIT"
$INSTALL_DIR = Read-Host "Installation directory [$DEFAULT_INSTALL_DIR]"
if ($INSTALL_DIR.Equals(""))
{
    $INSTALL_DIR = $DEFAULT_INSTALL_DIR
}

# Create the folder if it does not exist
if(!(Test-Path -Path $INSTALL_DIR ))
{
   New-Item -ItemType directory -Path $INSTALL_DIR | Out-Null

   # Test that creation was successful
   if(!(Test-Path -Path $INSTALL_DIR ))
   {
      Write-Host ""
      Write-Host "Could not create folder $INSTALL_DIR. Aborting." -ForegroundColor "red"
      exit 1
   }
}


# The final components folder must not exist!
if((Test-Path -Path $INSTALL_DIR\jre) -or (Test-Path -Path $INSTALL_DIR\obit_annotation_tool) -or (Test-Path -Path $INSTALL_DIR\obit_datamover_jsl))
{
   Write-Host ""
   Write-Host "It looks like $INSTALL_DIR already contains configured oBIT components." -ForegroundColor "red"
   Write-Host "Please delete the contents of $INSTALL_DIR (you can leave the downloaded packages) or pick another installation folder and restart the installer." -ForegroundColor "red"
   exit 1
}

# Java runtime
Write-Host "" 
Write-Host "--- JAVA RUNTIME ---" -ForegroundColor 'cyan'
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
    Write-Host -NoNewLine "In order to download the Java Runtime, you have to accept the Oracle license (please see "
    Write-Host -NoNewLine "http://www.oracle.com/technetwork/java/javase/terms/license/index.html" -ForegroundColor 'green'
    Write-Host ")."
    $ACCEPT_JAVA_LICENSE = Read-Host "Accept Oracle license? (y/n) [Y]"
    if ($ACCEPT_JAVA_LICENSE.Equals(""))
    {
        $ACCEPT_JAVA_LICENSE = "Y"
    }
    if ( -not $ACCEPT_JAVA_LICENSE.toUpper().Equals("Y"))
    {
        Write-Host "Exiting now." -ForegroundColor "red"
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
        $FINAL_JRE_PATH = Read-Host "Please specify the full path to the 'jre' folder [$DEFAULT_FINAL_JRE_PATH]"
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
        Write-Host "The selected path does not exist." -ForegroundColor "red"
        exit 1
    }

}
if ($SYSTEM_JAVA -ne "Y" -and $SYSTEM_JAVA -ne "N")
{
    Write-Host "Invalid answer." -ForegroundColor "red"
    exit 1
}

# ===========================================================================================
#
# oBIT CONFIGURATION
#
# ===========================================================================================

if ($JUST_DOWNLOAD_PACKAGES -eq "False")
{
    # oBIT configuration

    Write-Host ""
    Write-Host "--- oBIT CONFIGURATION ---" -ForegroundColor 'cyan'
    Write-Host ""
    Write-Host "To configure the various components of oBIT you will now be asked to provide some information."

    Write-Host ""
    Write-Host "-- [1] Local folders and user --"

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

       # Test that creation was successful
       if(!(Test-Path -Path $USER_FOLDER ))
       {
          Write-Host ""
          Write-Host "Could not create folder $USER_FOLDER. Aborting." -ForegroundColor "red"
          exit 1
       }
    }

    # Set Full Control to Everyone
    Set-FullPermission($USER_FOLDER)

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

       # Test that creation was successful
       if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER ))
       {
          Write-Host ""
          Write-Host "Could not create folder $DATAMOVER_DATA_FOLDER. Aborting." -ForegroundColor "red"
          exit 1
       }
    }

    # Subfolders
    $DATAMOVER_DATA_FOLDER_INCOMING = $DATAMOVER_DATA_FOLDER + "\incoming"
    $DATAMOVER_DATA_FOLDER_BUFFER   = $DATAMOVER_DATA_FOLDER + "\buffer"
    $DATAMOVER_DATA_FOLDER_MANUAL   = $DATAMOVER_DATA_FOLDER + "\manual_intervention"

    if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_INCOMING )){
       New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER_INCOMING | Out-Null

       # Test that creation was successful
       if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_INCOMING ))
       {
          Write-Host ""
          Write-Host "Could not create folder $DATAMOVER_DATA_FOLDER_INCOMING. Aborting." -ForegroundColor "red"
          exit 1
       }
    }
    if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_BUFFER )){
       New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER_BUFFER | Out-Null

       # Test that creation was successful
       if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_BUFFER ))
       {
          Write-Host ""
          Write-Host "Could not create folder $DATAMOVER_DATA_FOLDER_BUFFER. Aborting." -ForegroundColor "red"
          exit 1
       }
    }
    if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_MANUAL )){
       New-Item -ItemType directory -Path $DATAMOVER_DATA_FOLDER_MANUAL | Out-Null

       # Test that creation was successful
       if(!(Test-Path -Path $DATAMOVER_DATA_FOLDER_MANUAL ))
       {
          Write-Host ""
          Write-Host "Could not create folder $DATAMOVER_DATA_FOLDER_MANUAL. Aborting." -ForegroundColor "red"
          exit 1
       }    }

    # Set Full Control to Everyone
    Set-FullPermission($DATAMOVER_DATA_FOLDER)

    # Local user to run the Datamover as a Windows service
    Write-Host ""
    $DEFAULT_LOCAL_USER = "openbis"
    $LOCAL_USER = Read-Host "Local user to run Datamover as a Windows service [$DEFAULT_LOCAL_USER]"
    if ($LOCAL_USER.Equals(""))
    {
        $LOCAL_USER = $DEFAULT_LOCAL_USER
    }

    Write-Host ""
    Write-Host "-- [2] openBIS (AS) configuration --"

    # openBIS host
    Write-Host ""
    $OPENBIS_HOST = Read-Host "openBIS host"
    if ($OPENBIS_HOST.Equals(""))
    {
        # TODO: Ask again
        Write-Host "You must specify the openBIS host!" -ForegroundColor "red"
        exit 1
    }

    # openBIS server port (can be omitted)
    Write-Host ""
    $OPENBIS_PORT = Read-Host "openBIS host port (optional)"

    Write-Host ""
    Write-Host "-- [3] Datastore Server (DSS) configuration --"

    # Datastore server: by default, set it to the same as the openBIS host
    Write-Host ""
    $DEFAULT_DSS_HOST = $OPENBIS_HOST
    $DSS_HOST = Read-Host "Datastore server host [$DEFAULT_DSS_HOST]"
    if ($DSS_HOST.Equals(""))
    {
        $DSS_HOST = $DEFAULT_DSS_HOST
    }

    # Remote Datastore server user: by default, set it to the same as the local user.
    Write-Host ""
    $DEFAULT_DSS_USER = $LOCAL_USER
    $DSS_USER = Read-Host "Remote user to login to the Datastore server [$DEFAULT_DSS_USER]"
    if ($DSS_USER.Equals(""))
    {
        $DSS_USER = $DEFAULT_DSS_USER
    }

    # Remote dropbox folder on the Datastore server
    Write-Host ""
    $DSS_DROPBOX_PATH = Read-Host "Full path to the dropbox folder on the Datastore Server"
    if ($DSS_DROPBOX_PATH.Equals(""))
    {
        # TODO: Ask again
        Write-Host "The dropbox path cannot be mitted!" -ForegroundColor "red"
        exit 1 
    }

    # Path to the 'lastchanged' executable of Datamover on the Datastore server
    Write-Host ""
    $DSS_LASTCHANGED_PATH = Read-Host "Full path to the 'lastchanged' executable of Datamover on the Datastore server (optional)"

    Write-Host ""
    Write-Host "-- [4] Annotation Tool --"

    # Annotation Tool admin: acquisition type
    $ANNOTATION_TOOL_STATION_TYPES_OPTION_1 = "BD Biosciences Cell Analyzers and Sorters"
    $ANNOTATION_TOOL_STATION_TYPES_OPTION_2 = "Generic light microscopes"
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
        Write-Host "Invalid choice!" -ForegroundColor "red"
        exit 1 
    }

	# Annotation Tool admin: acquisition friendly hostname
	$DEFAULT_ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME = (Get-WmiObject -Class Win32_ComputerSystem -Property Name).Name
    Write-Host ""
    $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME = Read-Host "Specify a friendly and informative acquisition station name (if omitted, the hostname will be used) [$DEFAULT_ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME]"
	if ($ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME.Equals(""))
    {
        $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME = $DEFAULT_ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME
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
        Write-Host "Invalid choice!" -ForegroundColor "red"
        exit 1
    }
}

# ===========================================================================================
#
# If needed, create the local user
#
# ===========================================================================================

if ($JUST_DOWNLOAD_PACKAGES -eq "False")
{
    Write-Host "" 
    Write-Host "--- CHECKING LOCAL USER ---" -ForegroundColor 'cyan'
    
    Write-Host ""
    Write-Host "Please wait while checking local user '$LOCAL_USER'... " -NoNewline
    $user = Get-LocalUserAccount -ComputerName $env:COMPUTERNAME -UserName $LOCAL_USER
    if ($user -eq $null)
    {

        # Ask the user to provide a password
        Write-Host ""
        Write-Host "The local user '$LOCAL_USER' does not exist on this machine."
        $localUserPass1 = Read-Host 'Please enter a password for the new user:' -AsSecureString
        $localUserPass2 = Read-Host 'Please retype the password for confirmation:' -AsSecureString

        if (! ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($localUserPass1)) -ceq [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($localUserPass2))))
        {
           Write-Host "The two passwords do not match!" -ForegroundColor "red"
           exit 1
        }

        # Create the user
        Try
        {
            Add-LocalUserAccount -UserName $LOCAL_USER -Password ([String][Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($localUserPass1)))
            Write-Host "The local user '$LOCAL_USER' was successfully created."
        }
        Catch
        {
            Write-Host "User creation failed." -ForegroundColor "red"
            exit 1
        }
    }
    else 
    {
        Write-Host "The user exists."    
    }
}

# ===========================================================================================
#
# DOWNLOAD
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- DOWNLOADING PACKAGES ---" -ForegroundColor 'cyan'
Write-Host ""
Write-Host "Downloading $PLATFORM_N_BITS bit packages."
Write-Host ""

# If the expected files are already in the installation directory, we use those

# Target file
$DATAMOVER_JSL_OUTFILE  = $INSTALL_DIR + "\" + $DATAMOVER_JSL_FILENAME

if(Test-Path -Path $DATAMOVER_JSL_OUTFILE)
{
    Write-Host "Found file $DATAMOVER_JSL_OUTFILE. No need to download."
}
else
{
    # Get Datamover JSL
    Write-Host -NoNewline "Downloading Datamover JSL... "
    Invoke-WebRequest $DATAMOVER_JSL_URL -OutFile $DATAMOVER_JSL_OUTFILE
    Write-Host "Completed."
}

# Target file
$DATAMOVER_OUTFILE  = $INSTALL_DIR + "\" +  $DATAMOVER_FILENAME

if(Test-Path -Path $DATAMOVER_OUTFILE)
{
    Write-Host "Found file $DATAMOVER_OUTFILE. No need to download."
}
else
{
    # Get Datamover
    Write-Host -NoNewline "Downloading Datamover... "
    Invoke-WebRequest $DATAMOVER_URL -OutFile $DATAMOVER_OUTFILE
    Write-Host "Completed."
 }


# Target file
$OBIT_ANNOTATION_TOOL_OUTFILE  = $INSTALL_DIR + "\" + $OBIT_ANNOTATION_TOOL_FILENAME

if(Test-Path -Path $OBIT_ANNOTATION_TOOL_OUTFILE)
{
    Write-Host "Found file $OBIT_ANNOTATION_TOOL_OUTFILE. No need to download."
}
else
{
    # Get the Annotation Tool
    Write-Host -NoNewline "Downloading Annotation Tool... "
    Invoke-WebRequest $OBIT_ANNOTATION_TOOL_URL -OutFile $OBIT_ANNOTATION_TOOL_OUTFILE
    Write-Host "Completed."
}

# Target file
$JAVA_OUTFILE = $INSTALL_DIR + "\" + $JAVA_FILENAME

# Get Java (using cygwin wget)
if ($SYSTEM_JAVA.Equals("N"))
{
    if(Test-Path -Path $JAVA_OUTFILE)
    {
        Write-Host "Found file $JAVA_OUTFILE. No need to download."
    }
    else
    {
        Write-Host -NoNewline "Downloading JAVA... "
        & $WGET_EXE -P $INSTALL_DIR --quiet --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $JAVA_URL
        Write-Host "Completed."
    }
}
else
{
    Write-Host ""
    Write-Host "No need to download Java."
 }

# ===========================================================================================
#
# SHOULD WE EXIT HERE
#
# ===========================================================================================

if ($JUST_DOWNLOAD_PACKAGES -eq "True")
{
    Write-Host ""
    Write-Host "As requested, we stop here. The downloaded files are in $INSTALL_DIR."
    exit 0
}

# ===========================================================================================
#
# EXTRACT
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- EXTRACTING PACKAGES ---" -ForegroundColor 'cyan'
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
Write-Host "Completed."

Write-Host -NoNewline "Moving Datamover as a Windows Service components into place..."

# Copy the scripts folder for the right platform
New-Item -ItemType directory -Path $INSTALL_DIR\obit_datamover_jsl\datamover\scripts | Out-Null
$source = $INSTALL_DIR + "\obit_datamover_jsl\scripts\dist\" + $PLATFORM_N_BITS + "bit\*"
Copy-Item -Recurse $source $INSTALL_DIR\obit_datamover_jsl\datamover\scripts

# Create the home and .ssh folders for the local user
$sshFolder = $INSTALL_DIR + "\obit_datamover_jsl\datamover\bin\home\" + $LOCAL_USER + "\.ssh"
New-Item -ItemType directory -Path $sshFolder | Out-Null

Write-Host "Completed."

# Extract the Annotation Tool and create a shortcut on the Public desktop
Write-Host -NoNewline "Extracting Annotation Tool... "
Expand-ZIPFile –File $OBIT_ANNOTATION_TOOL_OUTFILE –Destination $INSTALL_DIR
Save-Shortcut $INSTALL_DIR\obit_annotation_tool\AnnotationTool.exe "C:\Users\Public\Desktop\Annotation Tool.lnk"
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
    }
    else
    {
        New-Item -ItemType directory -Path $INSTALL_DIR\jre | Out-Null
        & $TAR_EXE -zxf $JAVA_FILENAME -C jre --strip-components=1
    }
    Write-Host "Completed."
    Write-Host ""
    Write-Host "An error with following comment: 'gzip: stdin: decompression OK, trailing garbage ignored' can be safely ignored." -ForegroundColor "green"

    cd $PSScriptRoot
}

# ===========================================================================================
#
# Write all configuration files
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- CONFIGURING PACKAGES ---" -ForegroundColor 'cyan'
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
    -DSSUser $DSS_USER -DSSHost $DSS_HOST -DSSDropboxPath $DSS_DROPBOX_PATH `
    -DSSLastChangedPath $DSS_LASTCHANGED_PATH -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS

$sshFolder = $INSTALL_DIR + "\obit_datamover_jsl\datamover\bin\home\" + $LOCAL_USER + "\.ssh"
Write-SSH-Information -SshFolder $sshFolder -DSSHost $DSS_HOST -DSSUser $DSS_USER -LocalUser $LOCAL_USER

Write-Host "Completed."

# Configure Datamover JSL Windows service
Write-Host "Configuring Datamover as a Windows service..." -NoNewline
$DATAMOVER_JSL_PATH = $INSTALL_DIR + "\obit_datamover_jsl"
Configure-Datamover_JSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -LocalUser $LOCAL_USER -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS
Write-Host "Completed"

# Set up the aquisition station (i.e. create an Annotation Tool Admin XML settings file)
Write-Host "Setting up acquisition station..."
Create-AnnotationTool-Settings -UserFolder $USER_FOLDER -OpenBISHost $OPENBIS_HOST -OpenBISPort $OPENBIS_PORT `
    -DatamoverDataIncomingPath $DATAMOVER_DATA_FOLDER_INCOMING -AnnotationToolAdminAcqType $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE `
    -AcceptSelfSignedCertificates $ACCEPT_SELF_SIGNED_CERTIFICATES -AnnotationToolAdminAcqFriendlyName $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME
Write-Host "Completed"

# ===========================================================================================
#
# INSTALL DATAMOVER AS A WINDOWS SERVICE
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- INSTALLING DATAMOVER AS A WINDOWS SERIVCE ---" -ForegroundColor 'cyan'
Write-Host ""

# Does the user have a key or we need to generate one?
Write-Host ""
Write-Host "-- Public key authentication --"

# SSH key file with full path
$OUT_KEY_FILE = "$INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER\.ssh\key"

Write-Host ""
Write-Host "Datamover will transfer files from $DATAMOVER_DATA_FOLDER to the datastore server $DSS_HOST via secure copy."
Write-Host "For this, password-less key authentication is required. If you already have a key pair for the user '$DSS_USER' you can use that."
Write-Host "Otherwise you can create a new key pair here."
$key_option = Read-Host "[U]se existing or [C]reate a new key pair? (U, C) [C]"
if ($key_option.Equals(""))
{
    $key_option = "C"
}
$key_option = $key_option.toUpper()
if ($key_option.Equals("C"))
{

    # If the key already exists, delete it
    if (Test-Path -Path $OUT_KEY_FILE )
    {
        Remove-Item $OUT_KEY_FILE
    }

    Write-Host ""
    Write-Host "Please wait..."
    Write-Host ""

    # Generate key pair
    & $SSHKEYGEN_EXE -t rsa -b 4096 -N "''" -f $OUT_KEY_FILE

    Write-Host ""
    Write-Host "* * * IMPORTANT! * * *" -ForegroundColor 'magenta'
    Write-Host ""
    Write-Host "Add the content of the public key '$OUT_KEY_FILE.pub' to"
    Write-Host "the 'authorized_keys' file for user '$DSS_USER' on $DSS_HOST."
    Write-Host ""
    $ignore = Read-Host "Press ENTER when you are done"
}
elseif ($key_option.Equals("U"))
{
    # Ask the user to copy the private key to continue
    Write-Host ""
    Write-Host "* * * IMPORTANT! * * *" -ForegroundColor 'magenta'
    Write-Host ""
    Write-Host "Please paste your private key for user '$DSS_USER' and host $DSS_HOST into the file '$OUT_KEY_FILE'"
    Write-Host ""
    $ignore = Read-Host "Press ENTER when you are done"
}
else
{
    Write-Host "Bad choice '$key_option.'" -ForegroundColor "red"
    exit 1
}

# Set ownership of the home folder to the $LOCAL_USER
Set-Owner -Path $INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER -Account $env:COMPUTERNAME\$LOCAL_USER -Recurse 

# If the user never logged on to the Datastore server, we need to add the host to the known_hosts file
Write-Host ""
Write-Host "If this is the first time that '$DSS_USER' logs on to $DSS_HOST, we need to make sure that"
Write-Host "the know-hosts file contains the appropriate entry for the remote host: for this you need to"
Write-Host "log in once. Otherwise, you can skip this step."
Write-Host ""
$MUST_LOGIN = Read-Host "Do you want to try logging-in to the $DSS_HOST now? (y, n) [Y]"
if ($MUST_LOGIN.Equals(""))
{
    $MUST_LOGIN = "Y"
}
$MUST_LOGIN = $MUST_LOGIN.ToUpper()
if ($MUST_LOGIN.Equals("Y"))
{
    Write-Host ""
    Write-Host "Please follow these instructions." -ForegroundColor 'magenta'    
    Write-Host ""
    Write-Host "Please run 'cmd.exe' or 'powershell.exe' as the '$LOCAL_USER' user and type the following:"
    Write-Host ""
    Write-Host "cd $INSTALL_DIR\obit_datamover_jsl\datamover" -ForegroundColor 'cyan'
    Write-Host "bin\win\ssh.exe $DSS_HOST" -ForegroundColor 'cyan'
    Write-Host ""
    Write-Host "This will log in remotely as '$DSS_USER'."
    Write-Host ""
    Write-Host "If you get the following:"
    Write-Host ""
    Write-Host "The authenticity of host '$DSS_HOST' (XXX.XXX.XX.XXX) can't be established." -ForegroundColor 'gray'
    Write-Host "RSA key fingerprint is ..." -ForegroundColor 'gray'
    Write-Host "Are you sure you want to continue connecting (yes/no)?" -ForegroundColor 'gray'
    Write-Host ""
    Write-Host "Please reply 'yes'. You should get:"
    Write-Host ""
    Write-Host "Warning: Permanently added '$DSS_HOST,XXX.XX.XX.XXX' (RSA) to the list of known hosts." -ForegroundColor 'gray'
    Write-Host""
    Write-Host "Type 'exit' at the prompt to leave the server."
    Write-Host ""
    $ignore = Read-Host "Press ENTER when you are done"
}

# Inform the admin about the importance of securing the $DSS_USER home folder
Write-Host ""
Write-Host "It is highly recommended to prevent any user but '$($identity.Name)' and '$env:COMPUTERNAME\$LOCAL_USER' to access the" -ForegroundColor 'green'
Write-Host "$INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER folder. Failing to do so will" -ForegroundColor 'green'
Write-Host "give any quick-witted user the chance to borrow your private SSH key!" -ForegroundColor 'green'

# Does the service already exist?
$serviceName = "Datamover"
$service = Get-Service -Name $serviceName -ErrorVariable getServiceError -ErrorAction SilentlyContinue
if ($service -ne $null)
{
    Write-Host ""
    $REPLACE_SERVICE = Read-Host "Datamover as a Windows Service is already installed. Replace it? (y/n) [Y]"
    if ($REPLACE_SERVICE.Equals(""))
    {
        $REPLACE_SERVICE = "Y"
    }
    $REPLACE_SERVICE = $REPLACE_SERVICE.toUpper()
    if ($REPLACE_SERVICE.Equals("Y"))
    {
        Write-Host ""

        # Is it running?
        if ($service.Status -eq "running") {
            Stop-Service $serviceName
        }

        # Uninstall
        Remove-DataMoverJSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -PlatformNBits $PLATFORM_N_BITS

        # Install
        Install-DatamoverJSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -PlatformNBits $PLATFORM_N_BITS

    }
    else
    {
        Write-Host ""
        Write-Host "Datamover as a Windows Service will not be replaced."
        Write-Host "Please notice that if the current settings are different from the ones that you used last time" -ForegroundColor "green"
        Write-Host "Datamover might misbehave!" -ForegroundColor "green"
    }
}
else
{
    # Install
    Write-Host ""
    Install-DatamoverJSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -PlatformNBits $PLATFORM_N_BITS
}

# TODO Ask the user to type the password in the services toold for Datamover and start it
Write-Host ""
Write-Host "Please right-click on the $serviceName service, select Properties, change to the 'Log On' tab, type the '$LOCAL_USER' password and click OK."
Write-Host "Then start the $serviceName service."
& services.msc

# ===========================================================================================
#
# DELETE DOWNLOADED PACKAGES
#
# ===========================================================================================

Write-Host ""
$DELETE_DOWNLOADED_PACKAGES = Read-Host "Delete downloaded packages? (y/n) [Y]"
if ($DELETE_DOWNLOADED_PACKAGES.Equals(""))
{
    $DELETE_DOWNLOADED_PACKAGES = "Y"
}
$DELETE_DOWNLOADED_PACKAGES = $DELETE_DOWNLOADED_PACKAGES.ToUpper()
if ($DELETE_DOWNLOADED_PACKAGES.Equals("Y"))
{
    Remove-Item $DATAMOVER_JSL_OUTFILE
    Remove-Item $DATAMOVER_OUTFILE
    Remove-Item $OBIT_ANNOTATION_TOOL_OUTFILE
    Remove-Item $JAVA_OUTFILE
}

# ===========================================================================================
#
# Write a summary of all settings
#
# ===========================================================================================

# Inform
Write-Host "" 
Write-Host "--- WRITING SUMMARY ---" -ForegroundColor 'cyan'
Write-Host ""

$summaryFileName = "$PSScriptRoot\obit_settings_$env:COMPUTERNAME.txt"
Write-SettingsSummary -SummaryFileName $summaryFileName
Write-Host -NoNewline "Settings summary exported to "
Write-Host -NoNewline "$summaryFileName" -ForegroundColor 'green'
Write-Host "."

# Completed
Write-Host "" 
Write-Host "All done!" -ForegroundColor 'magenta' 
exit 0
