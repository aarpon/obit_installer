# ===========================================================================================
#
# oBIT URLS, PATHS
#
# ===========================================================================================

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
$OBIT_ANNOTATION_TOOL_VERSION  = "1.0.0"
$OBIT_ANNOTATION_TOOL_FILENAME = "obit_annotation_tool_" + $OBIT_ANNOTATION_TOOL_VERSION + "_" + $PLATFORM_N_BITS + "bit.zip"
$OBIT_ANNOTATION_TOOL_URL      = "https://github.com/aarpon/obit_annotation_tool/releases/download/" + $OBIT_ANNOTATION_TOOL_VERSION + "/" + $OBIT_ANNOTATION_TOOL_FILENAME

# JAVA JRE
$JAVA_BASE_URL = "http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/"
if ($PLATFORM_N_BITS -eq 64)
{
    $JAVA_FILENAME = "server-jre-8u161-windows-x64.tar.gz"
}
else
{
    $JAVA_FILENAME = "jre-8u161-windows-i586.tar.gz"
}
$JAVA_URL = $JAVA_BASE_URL + "/" + $JAVA_FILENAME

# JAVA FALLBACK URL
if ($PLATFORM_N_BITS -eq 64)
{
    $JAVA_URL_FALLBACK = "https://wiki-bsse.ethz.ch/download/attachments/152765137/server-jre-8u161-windows-x64.tar.gz"
}
else
{
    $JAVA_URL_FALLBACK = "https://wiki-bsse.ethz.ch/download/attachments/152765137/jre-8u161-windows-i586.tar.gz"
}
