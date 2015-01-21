# Write the Annotation Tool (Admin) configuration file
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

# Write the Annotation Tool configuration files
function Configure-AnnotationTool($annotationToolPath, $jrePath, $platformNBits)
{
    # Write the Annotation Tool Admin configuration
    Write-AnnotationToolConfig -AnnotationToolPath $annotationToolPath -JrePath $jrePath -PlatformNBits $platformNBits -IsAdmin True

    # Write the Annotation Tool configuration
    Write-AnnotationToolConfig -AnnotationToolPath $annotationToolPath -JrePath $jrePath -PlatformNBits $platformNBits -IsAdmin False
}

# Write the Datamover configuration file
function Configure-Datamover($datamoverPath, $datamoverDataIncomingPath, $datamoverDataBufferPath, `
    $datamoverDataManualPath, $remoteUser, $remoteHost, $remotePort, $remotePath, `
    $remoteLastChangedPath, $jrePath, $platformNBits)
{
    # Make sure to use forward slashes
    $datamoverDataIncomingPath = $datamoverDataIncomingPath -replace "\\", '/'
    $datamoverDataBufferPath   = $datamoverDataBufferPath -replace "\\", '/'
    $datamoverDataManualPath   = $datamoverDataManualPath -replace "\\", '/'
    $remotePath                = $remotePath -replace "\\", '/'
    $remoteLastChangedPath     = $remoteLastChangedPath -replace "\\", '/'

    # File name
    $fileName = $datamoverPath + "\etc\service.properties"
    
    # Open stream
    $stream = [System.IO.StreamWriter] $fileName

    # Write the file
    $stream.WriteLine("incoming-target = $datamoverDataIncomingPath")
    $stream.WriteLine("skip-accessibility-test-on-incoming = false")
    $stream.WriteLine("buffer-dir = $datamoverDataBufferPath")
    $stream.WriteLine("buffer-dir-highwater-mark = 1048576")
    $stream.WriteLine("outgoing-target = $remoteUser" + "@" + $remoteHost + ":" + $remotePort + $remotePath)
    $stream.WriteLine("outgoing-target-highwater-mark = 1048576")
    $stream.WriteLine("skip-accessibility-test-on-outgoing = true")
    $stream.WriteLine("data-completed-script = scripts/data_completed_script.bat")
    $stream.WriteLine("manual-intervention-dir = $datamoverDataManualPath")
    $stream.WriteLine("quiet-period = 60")
    $stream.WriteLine("check-interval = 60")
    if (! $remoteLastChangedPath -eq "")
    {
        $stream.WriteLine("outgoing-host-lastchanged-executable = $remoteLastChangedPath")
    }

    # Close stream
    $stream.close()
}

# Write the Datamover JSL configuration file
function Configure-Datamover_JSL($datamoverJSLPath, $localUser, $jrePath, $platformNBits)
{

    # File name
    $fileName = $datamoverJSLPath + "\jsl_static.ini"

    # Open stream
    $stream = [System.IO.StreamWriter] $fileName

    # Write the file
    $stream.WriteLine("[defines]")
    $stream.WriteLine("")

    $stream.WriteLine("[service]")
    $stream.WriteLine("appname = Datamover")
    $stream.WriteLine("servicename = Datamover")
    $stream.WriteLine("displayname = Datamover")
    $stream.WriteLine("servicedescription = Datamover as Windows Service")
    $stream.WriteLine("stringbuffer = 16000")
    $stream.WriteLine("starttype=auto")
    $stream.WriteLine("loadordergroup=someorder")
    $stream.WriteLine("useconsolehandler=false")
    $stream.WriteLine("stopclass=java/lang/System")
    $stream.WriteLine("stopmethod=exit")
    $stream.WriteLine("stopsignature=(I)V")
    $stream.WriteLine("account=.\$localUser")
    $stream.WriteLine("")

    $stream.WriteLine("[java]")
    $stream.WriteLine("jrepath=$jrePath")

    if ($platformNBits -eq 64)
    {
        $stream.WriteLine("jvmtype=server")
    }
    else
    {
        $stream.WriteLine("jvmtype=client")
    }

    $stream.WriteLine("wrkdir=$datamoverJSLPath\datamover")

    $stream.WriteLine("cmdline = -cp lib\datamover.jar;lib\log4j.jar;lib\cisd-base.jar;lib\cisd-args4j.jar;lib\commons-lang.jar;lib\commons-io.jar;lib\activation.jar;lib\mail.jar ch.systemsx.cisd.datamover.Main --rsync-executable=bin\win\rsync.exe --ssh-executable=bin\win\ssh.exe --ln-executable=bin\win\ln.exe")

    # Close stream
    $stream.close()

}

# Create the Annotation Tool settings for the acquisition machine
function Create-AnnotationTool-Settings($userFolder, $remoteHost, $remotePort, $datamoverDataIncomingPath, `
    $annotationToolAdminAcqType, $acceptSelfSignedCertificates)
{
    # Settings file path
    $settingsDirPath = $env:ProgramData + "\obit\AnnotationTool"
    $settingsFilePath = $settingsDirPath + "\settings.xml"

    # Create folders if needed
    if (! (Test-Path $settingsDirPath))
    {
        New-Item -ItemType Directory $settingsDirPath | Out-Null
    }

    # Build complete openBIS URL
    if ($remotePort -eq "")
    {
        $openBISURL = "https://$remoteHost/openbis"
    }
    else
    {
        $openBISURL = "https://$remoteHost" + ":" + "$remotePort/openbis"
    }
    
    # Create XML document
    [System.XML.XMLDocument] $doc = New-Object System.XML.XMLDocument
    [System.Xml.XmlDeclaration] $xmlDecl = $doc.CreateXmlDeclaration("1.0", "UTF-8", "no")
    $doc.AppendChild($xmlDecl) | Out-Null

    # Add "AnnotationTool_Properties element
    [System.XML.XMLElement] $root = $doc.CreateElement("AnnotationTool_Properties")
    $root.SetAttribute("version", "4")
    $doc.appendChild($root) | Out-Null

    # Add a "server" element
    [System.XML.XMLElement] $server = $doc.CreateElement("server")
    $server.SetAttribute("UserDataDir", $userFolder)
    $server.SetAttribute("DatamoverIncomingDir", $datamoverDataIncomingPath)
    $server.SetAttribute("AcquisitionStation", $annotationToolAdminAcqType)
    $server.SetAttribute("AcceptSelfSignedCertificates", $acceptSelfSignedCertificates)
    $server.SetAttribute("OpenBISURL", $openBISURL)
    $root.AppendChild($server) | Out-Null

    # Save file
    $doc.Save($settingsFilePath)

}

# Create the Annotation Tool settings for the acquisition machine
function Write-SSH-Information($sshFolder, $remoteHost, $remoteUser)
{
    # Write key
    $privateKeyFileName = $sshFolder + "\key"
    
    # Open stream
    $stream = [System.IO.StreamWriter] $privateKeyFileName

    # Write the key
    $stream.WriteLine("[PLEASE PASTE THE PRIVATE KEY FOR USER $remoteUser HERE!]")

    # Close stream
    $stream.close()

    # Write config file
    $configFileName = $sshFolder + "\config"

    # Open stream
    $stream = [System.IO.StreamWriter] $configFileName

    # Path to the key to save in the config file
    $privateKeyFileNamePosix = "/home/$remoteUser/.ssh/key"

    # Write the server configuration
    $stream.WriteLine("Host $remoteHost");
    $stream.WriteLine("    HostName $remoteHost");
    $stream.WriteLine("    User $remoteUser");
    $stream.WriteLine("    IdentityFile $privateKeyFileNamePosix");

    # Close stream
    $stream.close()

}

# Write a summary of all settings to Desktop
# Uses global variables
function Write-SettingsSummary()
{   
    # File name
    $fileName = [Environment]::GetFolderPath("Desktop") + "\obit_settings.txt"

    # Open stream
    $stream = [System.IO.StreamWriter] $fileName

    # Write the key
    $stream.WriteLine("[Settings]")
    $stream.WriteLine("")
    $stream.WriteLine("Installation dir                : $INSTALL_DIR")
    $stream.WriteLine("JAVA runtime in use             : $FINAL_JRE_PATH")
    $stream.WriteLine("User folder                     : $USER_FOLDER")
    $stream.WriteLine("Datamover data folder           : $DATAMOVER_DATA_FOLDER")
    $stream.WriteLine("Local user                      : $LOCAL_USER")
    $stream.WriteLine("Remote user                     : $REMOTE_USER")
    $stream.WriteLine("Remote host                     : $REMOTE_HOST")
    $stream.WriteLine("Remote host port                : $REMOTE_PORT")
    $stream.WriteLine("Remote dropbox path             : $REMOTE_PATH")
    $stream.WriteLine("Remote 'lastchanged' path       : $REMOTE_LASTCHANGED_PATH")
    $stream.WriteLine("Annotation Tool acquisition type: $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE")
    $stream.WriteLine("Accept self-signed certificates : $ACCEPT_SELF_SIGNED_CERTIFICATES")

    $stream.WriteLine("")
    $stream.WriteLine("[Generated configuration files]")
    $stream.WriteLine("")
    $stream.WriteLine("Datamover JSL                   : $INSTALL_DIR\obit_datamover_jsl\jsl_static.ini")
    $stream.WriteLine("Datamover                       : $INSTALL_DIR\obit_datamover_jsl\datamover\etc\service.properties")
    $stream.WriteLine("Annotation Tool                 : $INSTALL_DIR\obit_annotation_tool\AnnotationTool.ini")
    $stream.WriteLine("Annotation Tool Admin           : $INSTALL_DIR\obit_annotation_tool\AnnotationToolAdmin.ini")
    $stream.WriteLine("SSH key and config (secret!)    : $INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER\.ssh")

    $stream.WriteLine("")
    $stream.WriteLine("[Downloaded components]")
    $stream.WriteLine("")
    $stream.WriteLine("Platform                        : $PLATFORM_N_BITS bits")
    $stream.WriteLine("Datamover JSL                   : $DATAMOVER_JSL_URL")
    $stream.WriteLine("Datamover                       : $DATAMOVER_URL")
    $stream.WriteLine("Annotation Tool                 : $OBIT_ANNOTATION_TOOL_URL")
    $stream.WriteLine("JAVA Runtime                    : $JAVA_URL")
    
    # Close stream
    $stream.close()

}
