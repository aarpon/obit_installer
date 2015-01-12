# openBISImporterToolset (oBIT) installer
#
# This requires Windows Management Framework 4.0 and Windows > XP 
# http://www.microsoft.com/en-us/download/details.aspx?id=40855
#
# Copyright 2015 Aaron Ponti, Single Cell Unit, D-BSSE, ETH Zurich (Basel)

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
# FUNCTIONS
#
# ===========================================================================================

function Expand-ZIPFile($file, $destination)
{
    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
    }
}

function Write-AnnotationToolConfig($annotationToolPath, $jrePath, $platformNBits, $isAdmin)
{
    # Differences between AT and AT Admin
    if ($isAdmin -eq "True")
    {
        $fileName = $annotationToolPath + "\" + "AnnotationToolAdmin.ini"
        $mainClass = "ch.ethz.scu.obit.atadmin.AnnotationToolAdmin"
        $logFile = ".\log\annotation_tool_admin.log"
    }
    else
    {
        $fileName = $annotationToolPath + "\" + "AnnotationTool.ini"
        $mainClass = "ch.ethz.scu.obit.at.AnnotationTool"
        $logFile = ".\log\annotation_tool.log"
    }

    if ($platformNBits -eq 64)
    {
        $flavor = "server"
    }
    else
    {
        $flavor = "client"
    }

    # Open stream
    $stream = [System.IO.StreamWriter] $fileName

    # Write the file
    $stream.WriteLine("vm.location=$jrePath\bin\$flavor\jvm.dll")
    $stream.WriteLine("classpath.1=.\lib\*.jar")
    $stream.WriteLine("classpath.2=.\lib\*.zip")
    $stream.WriteLine("main.class=$mainClass")
    $stream.WriteLine("vmarg.1=-Xms256m")
    $stream.WriteLine("vmarg.2=-Xmx512m")
    $stream.WriteLine("vmarg.3=-XX:MaxPermSize=512m")
    $stream.WriteLine("log=.\log\annotation_tool.log")
    $stream.WriteLine("log.overwrite=true")
    $stream.WriteLine("log.file.and.console=true")
    $stream.WriteLine("log.roll.size=10")

    # Close stream
    $stream.close()

}

function Configure-AnnotationTool($annotationToolPath, $jrePath, $platformNBits)
{
    # Write the Annotation Tool Admin configuration
    Write-AnnotationToolConfig -AnnotationToolPath $annotationToolPath -JrePath $jrePath -PlatformNBits $platformNBits -IsAdmin True

    # Write the Annotation Tool configuration
    Write-AnnotationToolConfig -AnnotationToolPath $annotationToolPath -JrePath $jrePath -PlatformNBits $platformNBits -IsAdmin False
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
$INSTALL_DIR = Read-Host "Installation directory [$DEFAULT_INSTALL_DIR]"
if ($INSTALL_DIR.Equals(""))
{
    $INSTALL_DIR = $DEFAULT_INSTALL_DIR
}

# The installation directory must be empty
if(!(Test-Path -Path $INSTALL_DIR )){
   New-Item -ItemType directory -Path $INSTALL_DIR
}

$INSTALL_DIR_INFO = Get-ChildItem -force $INSTALL_DIR | Measure-Object
if ($INSTALL_DIR_INFO.count -gt 0)
{
    Write-Host "Sorry, the installation directory must be empty!"
    exit 1
}

# Use system-wide Java?
$DEFAULT_SYSTEM_JAVA = "N"
Write-Host ""
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
# URLS, DIRS AND PATHS
#
# ===========================================================================================

# Bin directory and tools
$BIN_DIR = $PSScriptRoot + "\bin"
$TAR_EXE = $BIN_DIR + "\tar.exe"
$WGET_EXE = $BIN_DIR + "\wget.exe"

# Temp directory
$TEMP_DIR = $env:temp

# DATAMOVER_JSL
$DATAMOVER_JSL_VERSION = "0.1.0"
$DATAMOVER_JSL_FILENAME = $DATAMOVER_JSL_VERSION + ".zip"
$DATAMOVER_JSL_URL      = "https://github.com/aarpon/obit_datamover_jsl/archive/" + $DATAMOVER_JSL_FILENAME
$DATAMOVER_JSL_OUTFILE  = $TEMP_DIR + "\" + $DATAMOVER_JSL_FILENAME 
$DATAMOVER_JSL_DESTFILE = $INSTALL_DIR + "\" +  $DATAMOVER_JSL_FILENAME

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
$JAVA_BASE_URL = "http://download.oracle.com/otn-pub/java/jdk/7u72-b14"
if ($PLATFORM_N_BITS -eq 64)
{
    $JAVA_FILENAME = "server-jre-7u72-windows-x64.tar.gz"
}
else
{
    $JAVA_FILENAME = "jre-7u71-windows-i586.tar.gz"
}
$JAVA_URL = $JAVA_BASE_URL + "/" + $JAVA_FILENAME
$JAVA_OUTFILE = $TEMP_DIR + "\" + $JAVA_FILENAME 

# ===========================================================================================
#
# DOWNLOAD
#
# ===========================================================================================

# Inform
Write-Host ""
Write-Host "Downloading packages..."

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
Write-Host "Extracting packages..."

# Extract Datamover JSL
Write-Host -NoNewline "Extracting Datamover JSL... "
Expand-ZIPFile –File $DATAMOVER_JSL_OUTFILE –Destination $INSTALL_DIR
Rename-Item $INSTALL_DIR\obit_datamover_jsl-$DATAMOVER_JSL_VERSION $INSTALL_DIR\obit_datamover_jsl
Write-Host "Completed."

# Extract Datamover
Write-Host -NoNewline "Extracting Datamover... "
Remove-Item -recurse $INSTALL_DIR\obit_datamover_jsl\datamover
Expand-ZIPFile –File $DATAMOVER_OUTFILE –Destination $INSTALL_DIR\obit_datamover_jsl
Write-Host "Completed."

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
Write-Host "Configuring packages..."

# Configure the Annotation Tool (Admin)
Write-Host -NoNewline "Configuring the Annotation Tool... "
$OBIT_ANNOTATION_TOOL_PATH = $INSTALL_DIR + "\obit_annotation_tool"
Configure-AnnotationTool -AnnotationToolPath $OBIT_ANNOTATION_TOOL_PATH -JrePath $FINAL_JRE_PATH -PlatformNBits $PLATFORM_N_BITS
Write-Host "Completed."

