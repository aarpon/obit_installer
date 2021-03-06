# openBISImporterToolset (oBIT) installer
#
# This requires Windows Management Framework 4.0, Microsoft .NET Framework 4.5 and Windows > XP
#   http://www.microsoft.com/en-us/download/details.aspx?id=40855
#   https://www.microsoft.com/en-us/download/details.aspx?id=42642
#
# For your convenience, the setup files for Windows 7 32 and 64 bit are in ./deps/.
#
# Usage:
#
#   .\obit_installer.ps1
#   .\obit_installes.ps1 -config_file path_to_config_file.json
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
# Copyright 2015 - 2021 Aaron Ponti, Single Cell Unit, D-BSSE, ETH Zurich (Basel)

# ===========================================================================================
#
# GET OPTIONAL SCRIPT ARGUMENT
#
# ===========================================================================================

Param([String]$CONFIG_FILE="")
if (! $CONFIG_FILE.Equals(""))
{
    # Check that the file exists
    if(!(Test-Path -Path $CONFIG_FILE ))
    {
        Write-Host "Sorry, cannot read the configuration file '$CONFIG_FILE'. Exiting." -ForegroundColor "red"
        exit 1
    }
}

# ===========================================================================================
#
# SET THE INSTALLER VERSION
#
# ===========================================================================================

$INSTALLER_VERSION = "2.2.0"

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
Write-Host "Copyright (c) 2015 - $(Get-Date -Format yyyy), Aaron Ponti, D-BSSE ETHZ Basel"
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

if (! $CONFIG_FILE.Equals(""))
{
    Write-Host "Using settings imported from configuration file '$CONFIG_FILE' as defaults." -ForegroundColor "green"
    Write-Host ""
}


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
# IMPORT REQUIREMENTS, BUILD ALL URLS AND PATHS FOR THE CHOSEN PLATFORM
#
# ===========================================================================================

# Add the bin directory to the path
$env:Path = "$PSScriptRoot\bin;" + $env:Path

# Import requirements
. "$PSScriptRoot\lib\util.ps1"
. "$PSScriptRoot\lib\conf.ps1"
. "$PSScriptRoot\lib\user.ps1"
. "$PSScriptRoot\lib\urls.ps1"

# ===========================================================================================
#
# SET DEFAULT VALUES OR IMPORT THEM FROM FILE, IF ONE WAS SPECIFIED
#
# ===========================================================================================

if ($CONFIG_FILE -eq "")
{
    $DEFAULT = Set-DefaultOptionValues
}
else
{
    $DEFAULT = Set-OptionValuesFromFile -fileName $CONFIG_FILE

    #  Check the version of the configuration file
    if ([int]$DEFAULT.SETTINGS_FILE_VERSION -lt 1)
    {
        Write-Host "The selected configuration file is obsolete and cannot be used!" -ForegroundColor "red"
        exit 1
    }
}

# ===========================================================================================
#
# LOAD DROPBOX FOLDER MAPPINGS
#
# ===========================================================================================

$HARDWAREDROPBOXMAP = Get-HardwareToDropboxFolderMap

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

$INSTALL_DIR = Read-Host "Installation directory [$($DEFAULT.INSTALL_DIR)]"
if ($INSTALL_DIR.Equals(""))
{
    $INSTALL_DIR = $DEFAULT.INSTALL_DIR
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
Write-Host "If you have an existing Java 8 installation, you can use that. Otherwise, the JRE will be downloaded and installed in $INSTALL_DIR (default)."
$SYSTEM_JAVA = Read-Host "Use existing Java installation (y/n) [$($DEFAULT.SYSTEM_JAVA)]"
if ($SYSTEM_JAVA.Equals(""))
{
    $SYSTEM_JAVA = $DEFAULT.SYSTEM_JAVA

    # Inform the user
    Write-Host ""
    Write-Host -NoNewLine "obit_installer will download the Amazon Corretto OpenJDK."

    # JAVA path
    $FINAL_JRE_PATH = $INSTALL_DIR + "\jre"

}
$SYSTEM_JAVA = $SYSTEM_JAVA.ToUpper()
if ($SYSTEM_JAVA.Equals("Y"))
{
    # Ask for the jre path
    if (Test-Path $DEFAULT.FINAL_JRE_PATH)
    {
        $FINAL_JRE_PATH = Read-Host "Please specify the full path to the 'jre' folder [$($DEFAULT.FINAL_JRE_PATH)]"
        if ($FINAL_JRE_PATH.Equals(""))
        {
            $FINAL_JRE_PATH = $DEFAULT.FINAL_JRE_PATH
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
    $USER_FOLDER = Read-Host "Annotation Tool user folder [$($DEFAULT.USER_FOLDER)]"
    if ($USER_FOLDER.Equals(""))
    {
        $USER_FOLDER = $DEFAULT.USER_FOLDER
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

    Write-Host "Setting permissions on $USER_FOLDER... " -NoNewline

    # Set Full Control to Everyone
    Set-FullPermissionToEveryone($USER_FOLDER)

    # Remove inherited permissions
    Remove-Inherited-Permissions($USER_FOLDER)

    Write-Host "Done."

    # Datamover data folder
    Write-Host ""
    $DATAMOVER_DATA_FOLDER = Read-Host "Datamover data folder [$($DEFAULT.DATAMOVER_DATA_FOLDER)]"
    if ($DATAMOVER_DATA_FOLDER.Equals(""))
    {
        $DATAMOVER_DATA_FOLDER = $DEFAULT.DATAMOVER_DATA_FOLDER
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

    Write-Host "Setting permissions on $DATAMOVER_DATA_FOLDER... " -NoNewline

    # Set Full Control to Everyone
    Set-FullPermissionToEveryone($DATAMOVER_DATA_FOLDER)

    # Remove inherited permissions
    Remove-Inherited-Permissions($DATAMOVER_DATA_FOLDER)

    Write-Host "Done."

    # Local user to run the Datamover as a Windows service
    Write-Host ""
    $LOCAL_USER = Read-Host "Local user to run Datamover as a Windows service [$($DEFAULT.LOCAL_USER)]"
    if ($LOCAL_USER.Equals(""))
    {
        $LOCAL_USER = $DEFAULT.LOCAL_USER
    }


    # Datamover service name
    Write-Host ""
    $DATAMOVER_SERVICE_NAME = Read-Host "Name of the Datamover as a Windows service [$($DEFAULT.DATAMOVER_SERVICE_NAME)]"
    if ($DATAMOVER_SERVICE_NAME.Equals(""))
    {
        $DATAMOVER_SERVICE_NAME = $DEFAULT.DATAMOVER_SERVICE_NAME
    }

    Write-Host ""
    Write-Host "-- [2] openBIS (AS) configuration --"

    # openBIS host (use the imported one, if it exists
    if ($DEFAULT.Keys -ccontains "IMPORTED_OPENBIS_HOST") {
        Write-Host ""
        $OPENBIS_HOST = Read-Host "openBIS host [$($DEFAULT.IMPORTED_OPENBIS_HOST)]"
        if ($OPENBIS_HOST.Equals(""))
        {
            $OPENBIS_HOST = $DEFAULT.IMPORTED_OPENBIS_HOST
        }
    }
    else
    {
        Write-Host ""
        $OPENBIS_HOST = Read-Host "openBIS host"
    }
    if ($OPENBIS_HOST.Equals(""))
    {
        # TODO: Ask again
        Write-Host "You must specify the openBIS host!" -ForegroundColor "red"
        exit 1
    }

    # openBIS server port (can be omitted)
    if ($DEFAULT.Keys -ccontains "IMPORTED_OPENBIS_PORT") {
        $ACCEPT_IMPORTED_OPENBIS_PORT = Read-Host "Use imported openBIS host port ('$($DEFAULT.IMPORTED_OPENBIS_PORT)')? (y/n) [Y]"
        if ($ACCEPT_IMPORTED_OPENBIS_PORT.Equals("") -or $ACCEPT_IMPORTED_OPENBIS_PORT.ToUpper().Equals("Y"))
        {
            $OPENBIS_PORT = $DEFAULT.IMPORTED_OPENBIS_PORT
        }
        else
        {
            Write-Host ""
            $OPENBIS_PORT = Read-Host "openBIS host port (optional)"
        }
    }
    else
    {
        Write-Host ""
        $OPENBIS_PORT = Read-Host "openBIS host port (optional)"
    }

    Write-Host ""
    Write-Host "-- [3] Datastore Server (DSS) configuration --"

    # Datastore server (use the imported one, if it exists; otherwise, set it to the same as the openBIS host).
    if ($DEFAULT.Keys -ccontains "IMPORTED_DSS_HOST") {
        $DEFAULT.DSS_HOST = $DEFAULT.IMPORTED_DSS_HOST
    }
    else
    {
        $DEFAULT.DSS_HOST = $OPENBIS_HOST
    }
    Write-Host ""
    $DSS_HOST = Read-Host "Datastore server host [$($DEFAULT.DSS_HOST)]"
    if ($DSS_HOST.Equals(""))
    {
        $DSS_HOST = $DEFAULT.DSS_HOST
    }

    # Remote Datastore server user (user the imported one, if it exists; otherwise, set it to the same as the local user).
    if ($DEFAULT.Keys -ccontains "IMPORTED_DSS_USER") {
        $DEFAULT.DSS_USER = $DEFAULT.IMPORTED_DSS_USER
    }
    else
    {
        $DEFAULT.DSS_USER = $LOCAL_USER
    }
    Write-Host ""
    $DSS_USER = Read-Host "Remote user to login to the Datastore server [$($DEFAULT.DSS_USER)]"
    if ($DSS_USER.Equals(""))
    {
        $DSS_USER = $DEFAULT.DSS_USER
    }

    # Remote dropbox folder on the Datastore server (user the imported one, if it exists).
    if ($DEFAULT.Keys -ccontains "IMPORTED_DSS_DROPBOX_PATH") {
        Write-Host ""
        $ACCEPT_DSS_DROPBOX_PATH = Read-Host "Accept full path to the dropbox folder on the Datastore Server ($($DEFAULT.IMPORTED_DSS_DROPBOX_PATH))? (y/n) [Y]"
        if ($ACCEPT_DSS_DROPBOX_PATH.Equals(""))
        {
            $ACCEPT_DSS_DROPBOX_PATH = "Y"
        }
        $ACCEPT_DSS_DROPBOX_PATH = $ACCEPT_DSS_DROPBOX_PATH.ToUpper()
        if ($ACCEPT_DSS_DROPBOX_PATH.Equals("Y"))
        {
            Write-Host "Accepted path."
            $DSS_DROPBOX_PATH = $DEFAULT.IMPORTED_DSS_DROPBOX_PATH
            $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = $DEFAULT.IMPORTED_ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE
        }
        else
        {
            Write-Host "Rejected path."
            $DSS_DROPBOX_PATH = ""
            $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = ""
        }
    }
    else
    {
        $DSS_DROPBOX_PATH = ""
        $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = ""
    }

    # If the dropbox path was not imported (or not accepted), we ask the admin to configure it again
    if ($DSS_DROPBOX_PATH.Equals(""))
    {
        Write-Host ""
        $DSS_DROPBOX_PATH = Read-Host "Full path to the data folder on the Datastore Server (parent to the data store and the dropbox folders)"
        if ($DSS_DROPBOX_PATH.Equals(""))
        {
            # TODO: Ask again
            Write-Host "The dropbox path cannot be omitted!" -ForegroundColor "red"
            exit 1
        }
    }

    # Path to the 'lastchanged' executable of Datamover on the Datastore server (use the imported one, if it exists).
    if ($DEFAULT.Keys -ccontains "IMPORTED_DSS_LASTCHANGED_PATH") {
        Write-Host ""
        $DSS_LASTCHANGED_PATH = Read-Host "Full path to the 'lastchanged' executable of Datamover on the Datastore server (optional) [$($DEFAULT.IMPORTED_DSS_LASTCHANGED_PATH)]"
        if ($DSS_LASTCHANGED_PATH.Equals(""))
        {
            $DSS_LASTCHANGED_PATH = $DEFAULT.IMPORTED_DSS_LASTCHANGED_PATH
        }
    }
    else
    {
        Write-Host ""
        $DSS_LASTCHANGED_PATH = Read-Host "Full path to the 'lastchanged' executable of Datamover on the Datastore server (optional)"
    }

    Write-Host ""
    Write-Host "-- [4] Annotation Tool --"

    # Annotation Tool admin: acquisition type
    # If the full dropbox path was already set (i.e. imported with or without modification from a settings file)
    # we do not need to ask the user to configure the acquisition stations.
    if ($ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE -eq "")
    {
        Write-Host ""
        Write-Host "Select the acquisition station or type the Annotation Tool is going to manage:"
        Write-Host "    [1] $($DEFAULT.ANNOTATION_TOOL_STATION_TYPES_OPTION_1)"
        Write-Host "    [2] $($DEFAULT.ANNOTATION_TOOL_STATION_TYPES_OPTION_2)"
        $selectedStationOption = Read-Host "Your choice"
        If ($selectedStationOption -eq 1)
        {
            $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = $DEFAULT.ANNOTATION_TOOL_STATION_TYPES_OPTION_1
        }
        elseif ($selectedStationOption -eq 2)
        {
            $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE = $DEFAULT.ANNOTATION_TOOL_STATION_TYPES_OPTION_2
        }
        else
        {
            # TODO: Ask again
            Write-Host "Invalid choice!" -ForegroundColor "red"
            exit 1
        }

        # Actual hardware (in case $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE is 2)
        if ($ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE -eq "Flow Cytometry")
        {
            # Ask for the hardware type
            Write-Host ""
            Write-Host "Pick the machine:"
            Write-Host "    [1] BD LSR Fortessa"
            Write-Host "    [2] BD FACS Aria"
            Write-Host "    [3] BD Influx"
            Write-Host "    [4] Biorad S3e"
            Write-Host "    [5] Beckman Coulter MoFlo XDP"
            Write-Host "    [6] Beckman Coulter CytoFLEX S"
            Write-Host "    [7] Sony SH800S"
            Write-Host "    [8] Sony MA900"
            $selectedMachine = Read-Host "Your choice"
            if ($selectedMachine -eq "1")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.BDLSRFORTESSA
            }
            elseif  ($selectedMachine -eq "2")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.BDFACSARIA
            }
            elseif  ($selectedMachine -eq "3")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.BDINFLUX
            }
            elseif  ($selectedMachine -eq "4")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.BIORADS3E
            }
            elseif  ($selectedMachine -eq "5")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.BCMOFLOXDP
            }
            elseif  ($selectedMachine -eq "6")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.BCCYTOFLEXS
            }
            elseif  ($selectedMachine -eq "7")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.SONYSH800S
            }
            elseif  ($selectedMachine -eq "8")
            {
                $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.SONYMA900
            }
            else
            {
                # TODO: Ask again
                Write-Host "Invalid choice!" -ForegroundColor "red"
                exit 1
            }
        }
        elseif ($ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE -eq "Microscopy")
        {
            $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH + "/" + $HARDWAREDROPBOXMAP.MICROSCOPY
        }
        else
        {
            Write-Host "Invalid acquisition type!" -ForegroundColor "red"
            exit 1
        }

    }
    else
    {
        # We do not need to change anything.
    }

    # Summarize the acquisition station and dropbox since we have quite a few options
    $DSS_DROPBOX_PATH = $DSS_DROPBOX_PATH -replace "//", "/"
    Write-Host ""
    Write-Host "The acquisition station type is '$ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE' and the full path to the dropbox folder is '$DSS_DROPBOX_PATH'."

	# Annotation Tool admin: acquisition friendly hostname
    # Since this should be unique for each machine, we do not use the imported value.
    Write-Host ""
    $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME = Read-Host "Specify a friendly and informative acquisition station name (if omitted, the hostname will be used)"
	if ($ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME.Equals(""))
    {
        $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME = $DEFAULT.ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME
    }

    # Annotation Tool admin: self-signed SSL certificates
    if ($DEFAULT.ACCEPT_SELF_SIGNED_CERTIFICATES.Equals("yes") -or $DEFAULT.ACCEPT_SELF_SIGNED_CERTIFICATES.toUpper().Equals("Y"))
    {
        $TRANSLATED_ACCEPT_SELF_SIGNED_CERTIFICATES = "Y";
    }
    else
    {
        $TRANSLATED_ACCEPT_SELF_SIGNED_CERTIFICATES = "N"
    }
    Write-Host ""
    Write-Host "Depending on how openBIS was installed, you might need to force accepting self-signed certificates for the Annotation Tool to be able to login from the acquisition station."
    $ACCEPT_SELF_SIGNED_CERTIFICATES = Read-Host "Accept self-signed certificates? (y/n) [$TRANSLATED_ACCEPT_SELF_SIGNED_CERTIFICATES]"
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
    if ($null -eq $user)
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
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest $JAVA_URL -OutFile $JAVA_OUTFILE

        # Was the download successful?
        if(Test-Path -Path $JAVA_OUTFILE)
        {
            Write-Host "Completed."
        }
        else
        {
            Write-Host -NoNewline "Could not download JAVA from aws.amazon.com. Trying fallback URL..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $JAVA_URL_FALLBACK -OutFile $JAVA_OUTFILE

            # Was THIS download successful?
            if(Test-Path -Path $JAVA_OUTFILE)
            {
                Write-Host "Completed."
            }
            else
            {
                Write-Host "Sorry, JAVA could not be downloaded." -ForegroundColor "red"
            }
        }
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
    Expand-ZIPFile –File $INSTALL_DIR\$JAVA_FILENAME -Destination $INSTALL_DIR
    Move-Item $INSTALL_DIR\jre8 $INSTALL_DIR\jre
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
Configure-Datamover_JSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -DatamoverServiceName $DATAMOVER_SERVICE_NAME -LocalUser $LOCAL_USER -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS
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
$key_option = Read-Host "[U]se existing or [C]reate a new key pair? (U, C) [U]"
if ($key_option.Equals(""))
{
    $key_option = "U"
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
    Read-Host "Press ENTER when you are done"
}
elseif ($key_option.Equals("U"))
{
    # Ask the user to copy the private key to continue
    Write-Host ""
    Write-Host "* * * IMPORTANT! * * *" -ForegroundColor 'magenta'
    Write-Host ""
    Write-Host "Please paste your private key for user '$DSS_USER' and host $DSS_HOST into the file '$OUT_KEY_FILE'"
    Write-Host ""
    Read-Host "Press ENTER when you are done"
}
else
{
    Write-Host "Bad choice '$key_option.'" -ForegroundColor "red"
    exit 1
}

# Set ownership of the home folder and limit access to $LOCAL_USER
Write-Host "Restricting permissions to '$LOCAL_USER' home folder (and ssh key)... " -NoNewline
Set-FullPermissionToUser -Folder "$INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER" -UserName "$env:COMPUTERNAME\$LOCAL_USER"
Remove-Inherited-Permissions -Folder "$INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER"
Set-Owner -Path $INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER -Account $env:COMPUTERNAME\$LOCAL_USER -Recurse
Write-Host "Done."

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
    Read-Host "Press ENTER when you are done"
}

# Does the Datamover service already exist?
$service = Get-Service -Name $DATAMOVER_SERVICE_NAME -ErrorVariable getServiceError -ErrorAction SilentlyContinue
if ($null -ne $service)
{
    Write-Host ""
    $REPLACE_SERVICE = Read-Host "Datamover as a Windows Service ('$DATAMOVER_SERVICE_NAME') is already installed. Replace it? (y/n) [Y]"
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
            Stop-Service $DATAMOVER_SERVICE_NAME
        }

        # Uninstall
        Remove-DataMoverJSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -PlatformNBits $PLATFORM_N_BITS

        # Install
        Install-DatamoverJSL -DatamoverJSLPath $DATAMOVER_JSL_PATH -PlatformNBits $PLATFORM_N_BITS

    }
    else
    {
        Write-Host ""
        Write-Host "Datamover as a Windows Service ('$DATAMOVER_SERVICE_NAME') will not be replaced."
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
Write-Host "Please right-click on the $DATAMOVER_SERVICE_NAME service, select Properties, change to the 'Log On' tab, type the '$LOCAL_USER' password and click OK."
Write-Host "Then start the $DATAMOVER_SERVICE_NAME service."
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

$settingsJSONFileName = "$PSScriptRoot\obit_settings_$env:COMPUTERNAME.json"
Write-Settings -SettingsFileName $settingsJSONFileName
Write-Host -NoNewline "Settings saved to "
Write-Host -NoNewline "$settingsJSONFileName" -ForegroundColor 'green'
Write-Host "."

# Completed
Write-Host ""
Write-Host "All done!" -ForegroundColor 'magenta'
exit 0
