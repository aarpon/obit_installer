# ===========================================================================================
#
# MACHINE CONSTANTS
#
# ===========================================================================================

if ($USER_PLATFORM_N_BITS -ne $null)
{
    if (($USER_PLATFORM_N_BITS -ne 32) -and ($USER_PLATFORM_N_BITS -ne 64))
    {
        Write-Host "Error: $USER_PLATFORM_N_BITS must be either null, 32 or 64!"
        exit 1
    }
    $PLATFORM_N_BITS = $USER_PLATFORM_N_BITS
}
else
{
    $PLATFORM_N_BITS = (Get-WmiObject -Class Win32_Processor).AddressWidth
}

# ===========================================================================================
#
# oBIT CONSTANTS
#
# ===========================================================================================

$ANNOTATION_TOOL_STATION_TYPES_OPTION_1 = "BD BioSciences Cell Analyzers and Sorters"
$ANNOTATION_TOOL_STATION_TYPES_OPTION_2 = "Generic light microscopes"

# ===========================================================================================
#
# oBIT URLS, PATHS
#
# ===========================================================================================

# Bin directory and tools
$BIN_DIR = $PSScriptRoot + "\..\bin"
$TAR_EXE = $BIN_DIR + "\tar.exe"
$WGET_EXE = $BIN_DIR + "\wget.exe"

# Temp directory
$TEMP_DIR = $env:temp

# DATAMOVER_JSL
$DATAMOVER_JSL_VERSION = "0.1.0"
$DATAMOVER_JSL_FILENAME = $DATAMOVER_JSL_VERSION + ".zip"
$DATAMOVER_JSL_URL      = "https://github.com/aarpon/obit_datamover_jsl/archive/" + $DATAMOVER_JSL_FILENAME

# DATAMOVER
$DATAMOVER_FILENAME = "datamover-13.07.0-r29510.zip"
$DATAMOVER_URL      = "https://wiki-bsse.ethz.ch/download/attachments/21567716/" + $DATAMOVER_FILENAME

# ANNOTATION TOOL
$OBIT_ANNOTATION_TOOL_VERSION  = "0.5.4"
$OBIT_ANNOTATION_TOOL_FILENAME = "obit_annotation_tool_" + $OBIT_ANNOTATION_TOOL_VERSION + "_" + $PLATFORM_N_BITS + "bit.zip"
$OBIT_ANNOTATION_TOOL_URL      = "https://github.com/aarpon/obit_annotation_tool/releases/download/" + $OBIT_ANNOTATION_TOOL_VERSION + "/" + $OBIT_ANNOTATION_TOOL_FILENAME

# JAVA JRE
$JAVA_BASE_URL = "http://download.oracle.com/otn-pub/java/jdk/7u72-b14"
if ($PLATFORM_N_BITS -eq 64)
{
    $JAVA_FILENAME = "server-jre-7u72-windows-x64.tar.gz"
}
else
{
    $JAVA_FILENAME = "jre-7u72-windows-i586.tar.gz"
}
$JAVA_URL = $JAVA_BASE_URL + "/" + $JAVA_FILENAME
