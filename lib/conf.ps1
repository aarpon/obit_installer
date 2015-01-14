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
    $stream.WriteLine("[PLEASE PASTE THE PRIVATE KEY FOR USER $remoteUser HERE!]");

    # Close stream
    $stream.close()

    # Write config file
    $configFileName = $sshFolder + "\config"

    # Open stream
    $stream = [System.IO.StreamWriter] $configFileName

    # Write the server configuration
    $stream.WriteLine("Host $remoteHost");
    $stream.WriteLine("    HostName $remoteHost");
    $stream.WriteLine("    User $remoteUser");
    $stream.WriteLine("    IdentityFile $privateKeyFileName");

    # Close stream
    $stream.close()

}
