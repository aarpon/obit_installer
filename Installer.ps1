# openBISImporterToolset (oBIT) installer
#
# This requires Windows Management Framework 4.0 and Windows > XP 
# http://www.microsoft.com/en-us/download/details.aspx?id=40855
#
# Copyright 2015 Aaron Ponti, Single Cell Unit, D-BSSE, ETH Zurich (Basel)

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
throw "This script must be run from an elevated shell."
}

# ===========================================================================================
#
# TOOLS
#
# ===========================================================================================

function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}
}

# ===========================================================================================
#
# PLATFORM INFORMATION
#
# ===========================================================================================

# Get OS and architecture
#OS = ...
$PLATFORM_N_BITS = (Get-WmiObject -Class Win32_Processor).addresswidth

# ===========================================================================================
#
# USER INPUT
#
# Remark: to hide passwods, use $pass = Read-Host 'What is your password?' -AsSecureString
#
# ===========================================================================================

# Installation directory
$DEFAULT_INSTALL_DIR = "C:\oBIT"
$INSTALL_DIR = Read-Host "Installation directory [$DEFAULT_INSTALL_DIR]: "
if ($INSTALL_DIR.Equals(""))
{
    $INSTALL_DIR = $DEFAULT_INSTALL_DIR
}

# Use system-wide Java?
$DEFAULT_SYSTEM_JAVA = "N"
$SYSTEM_JAVA = Read-Host "Use system Java (y/n) [$DEFAULT_SYSTEM_JAVA]: "
if ($SYSTEM_JAVA.Equals(""))
{
    $SYSTEM_JAVA = $DEFAULT_SYSTEM_JAVA
}
$SYSTEM_JAVA = $SYSTEM_JAVA.ToUpper()
if ($SYSTEM_JAVA -ne "Y" -and $SYSTEM_JAVA -ne "N")
{
throw "Invalid answer."
}


# ===========================================================================================
#
# URLS, DIRS AND PATHS
#
# ===========================================================================================

# Temp directory
$TEMP_DIR = $env:temp

# DATAMOVER
$DATAMOVER_FILENAME = "datamover-13.07.0-r29510.zip"
$DATAMOVER_URL      = "https://wiki-bsse.ethz.ch/download/attachments/21567716/" + $DATAMOVER_FILENAME
$DATAMOVER_OUTFILE  = $TEMP_DIR + "\" +  $DATAMOVER_FILENAME
$DATAMOVER_DESTFILE = $INSTALL_DIR + "\" +  $DATAMOVER_FILENAME

# ANNOTATION TOOL
$OBIT_ANNOTATION_TOOL_VERSION  = "0.5.4"
$OBIT_ANNOTATION_TOOL_FILENAME = "obit_annotation_tool_" + $OBIT_ANNOTATION_TOOL_VERSION + "_" + $PLATFORM_N_BITS + "bit.zip"
$OBIT_ANNOTATION_TOOL_URL      = "https://github.com/aarpon/obit_annotation_tool/releases/download/" + $OBIT_ANNOTATION_TOOL_VERSION + "/" + $OBIT_ANNOTATION_TOOL_FILENAME
$OBIT_ANNOTATION_TOOL_OUTFILE  = $TEMP_DIR + "\" + $OBIT_ANNOTATION_TOOL_FILENAME

# JAVA JRE
if ($PLATFORM_N_BITS -eq 64)
{
$JAVA_URL = "http://download.oracle.com/otn-pub/java/jdk/7u72-b14/server-jre-7u72-windows-x64.tar.gz"
}
else
{
$JAVA_URL = "http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jre-7u71-windows-i586.tar.gz"
}

# ===========================================================================================
#
# CHECK FOR EXISTANCE OF RELEVANT FOLDERS
#
# ===========================================================================================

if(!(Test-Path -Path $INSTALL_DIR )){
   New-Item -ItemType directory -Path $INSTALL_DIR
}

# ===========================================================================================
#
# DOWNLOAD
#
# ===========================================================================================

# Get Datamover
Write-Host -NoNewline "Downloading Datamover... "
Invoke-WebRequest $DATAMOVER_URL -OutFile $DATAMOVER_OUTFILE
Write-Host "Completed."

# Get the Annotation Tool
Write-Host -NoNewline "Downloading Annotation Tool... "
Invoke-WebRequest $OBIT_ANNOTATION_TOOL_URL -OutFile $OBIT_ANNOTATION_TOOL_OUTFILE
Write-Host "Completed."

# ===========================================================================================
#
# EXTRACT
#
# ===========================================================================================

# Extract Datamover
Write-Host -NoNewline "Extracting Datamover... "
Expand-ZIPFile –File $DATAMOVER_OUTFILE –Destination $INSTALL_DIR
Write-Host "Completed."

# Extract the Annotation Tool
Write-Host -NoNewline "Extracting Annotation Tool... "
Expand-ZIPFile –File $OBIT_ANNOTATION_TOOL_OUTFILE –Destination $INSTALL_DIR
Write-Host "Completed."
