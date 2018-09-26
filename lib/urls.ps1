# ===========================================================================================
#
# oBIT URLS, PATHS, VERSIONS
#
# ===========================================================================================

# oBIT Installer settings file version
$SETTINGS_FILE_VERSION = "1";

# Annotation Tool settings file version (C:\ProgramData\obit\AnnotationTool\settings.xml)
$AT_SETTINGS_FILE_VERSION = "7";

# Bin directory and tools
$BIN_DIR = $PSScriptRoot + "\..\bin"
$TAR_EXE = $BIN_DIR + "\tar.exe"
$WGET_EXE = $BIN_DIR + "\wget.exe"
$SSHKEYGEN_EXE = $BIN_DIR + "\ssh-keygen.exe"

# DATAMOVER_JSL
$DATAMOVER_JSL_VERSION = "0.2.0"
$DATAMOVER_JSL_FILENAME = $DATAMOVER_JSL_VERSION + ".zip"
$DATAMOVER_JSL_URL      = "https://github.com/aarpon/obit_datamover_jsl/archive/" + $DATAMOVER_JSL_FILENAME

# DATAMOVER
$DATAMOVER_FILENAME = "datamover-15.06.0-r34542.zip"
$DATAMOVER_URL      = "https://wiki-bsse.ethz.ch/download/attachments/21567716/" + $DATAMOVER_FILENAME

# ANNOTATION TOOL
$OBIT_ANNOTATION_TOOL_VERSION  = "1.1.1"
$OBIT_ANNOTATION_TOOL_FILENAME = "obit_annotation_tool_" + $OBIT_ANNOTATION_TOOL_VERSION + "_" + $PLATFORM_N_BITS + "bit.zip"
$OBIT_ANNOTATION_TOOL_URL      = "https://github.com/aarpon/obit_annotation_tool/releases/download/" + $OBIT_ANNOTATION_TOOL_VERSION + "/" + $OBIT_ANNOTATION_TOOL_FILENAME

# JAVA JRE
$JAVA_BASE_URL = "http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/"
if ($PLATFORM_N_BITS -eq 64)
{
    $JAVA_FILENAME = "server-jre-8u181-windows-x64.tar.gz"
}
else
{
    $JAVA_FILENAME = "jre-8u181-windows-i586.tar.gz"
}
$JAVA_URL = $JAVA_BASE_URL + "/" + $JAVA_FILENAME

# JAVA FALLBACK URL
if ($PLATFORM_N_BITS -eq 64)
{
    $JAVA_URL_FALLBACK = "https://wiki-bsse.ethz.ch/download/attachments/152765137/server-jre-8u181-windows-x64.tar.gz"
}
else
{
    $JAVA_URL_FALLBACK = "https://wiki-bsse.ethz.ch/download/attachments/152765137/jre-8u181-windows-i586.tar.gz" 
}
