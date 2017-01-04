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
    $datamoverDataManualPath, $dssUser, $dssHost, $dssDropboxPath, $dssLastChangedPath, $jrePath, $platformNBits)
{
    # Make sure to use forward slashes
    $datamoverDataIncomingPath = $datamoverDataIncomingPath -replace "\\", '/'
    $datamoverDataBufferPath   = $datamoverDataBufferPath -replace "\\", '/'
    $datamoverDataManualPath   = $datamoverDataManualPath -replace "\\", '/'
    $dssDropboxPath            = $dssDropboxPath -replace "\\", '/'
    $dssLastChangedPath        = $dssLastChangedPath -replace "\\", '/'

    # File name
    $fileName = $datamoverPath + "\etc\service.properties"

    # Open stream
    $stream = [System.IO.StreamWriter] $fileName

    # Write the file
    $stream.WriteLine("incoming-target = $datamoverDataIncomingPath")
    $stream.WriteLine("skip-accessibility-test-on-incoming = false")
    $stream.WriteLine("buffer-dir = $datamoverDataBufferPath")
    $stream.WriteLine("buffer-dir-highwater-mark = 1048576")
    $stream.WriteLine("outgoing-target = $dssUser" + "@" + $dssHost + ":" + $dssDropboxPath)
    $stream.WriteLine("outgoing-target-highwater-mark = 1048576")
    $stream.WriteLine("skip-accessibility-test-on-outgoing = true")
    $stream.WriteLine("data-completed-script = scripts/data_completed_script.bat")
    $stream.WriteLine("manual-intervention-dir = $datamoverDataManualPath")
    $stream.WriteLine("quiet-period = 60")
    $stream.WriteLine("check-interval = 60")
    if (! $dssLastChangedPath -eq "")
    {
        $stream.WriteLine("outgoing-host-lastchanged-executable = $dssLastChangedPath")
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
function Create-AnnotationTool-Settings($userFolder, $openBISHost, $openBISPort, $datamoverDataIncomingPath, `
    $annotationToolAdminAcqType, $acceptSelfSignedCertificates, $annotationToolAdminAcqFriendlyName)
{
    # Settings file path
    $settingsDirPath = $env:ProgramData + "\obit\AnnotationTool"
    $settingsFilePath = $settingsDirPath + "\settings.xml"

    # Create folders if needed
    if (! (Test-Path $settingsDirPath))
    {
        New-Item -ItemType Directory $settingsDirPath | Out-Null

        # Test that creation was successful
        if(!(Test-Path -Path $settingsDirPath ))
        {
           Write-Host ""
           Write-Host "Could not create folder $settingsDirPath. Aborting." -ForegroundColor "red"
           exit 1
        }
    }

    # Build complete openBIS URL
    if ($openBISPort -eq "")
    {
        $openBISURL = "https://$openBISHost/openbis"
    }
    else
    {
        $openBISURL = "https://$openBISHost" + ":" + "$openBISPort/openbis"
    }
    
    # Create XML document
    [System.XML.XMLDocument] $doc = New-Object System.XML.XMLDocument
    [System.Xml.XmlDeclaration] $xmlDecl = $doc.CreateXmlDeclaration("1.0", "UTF-8", "no")
    $doc.AppendChild($xmlDecl) | Out-Null

    # Add "AnnotationTool_Properties element
    [System.XML.XMLElement] $root = $doc.CreateElement("AnnotationTool_Properties")
    $root.SetAttribute("version", "6")
    $doc.appendChild($root) | Out-Null

    # Add a "server" element
    [System.XML.XMLElement] $server = $doc.CreateElement("server")
    $server.SetAttribute("UserDataDir", $userFolder)
    $server.SetAttribute("DatamoverIncomingDir", $datamoverDataIncomingPath)
    $server.SetAttribute("AcquisitionStation", $annotationToolAdminAcqType)
	$server.SetAttribute("HumanFriendlyHostName", $annotationToolAdminAcqFriendlyName)
    $server.SetAttribute("AcceptSelfSignedCertificates", $acceptSelfSignedCertificates)
    $server.SetAttribute("OpenBISURL", $openBISURL)
    $root.AppendChild($server) | Out-Null

    # Save file
    $doc.Save($settingsFilePath)

}

# Create the Annotation Tool settings for the acquisition machine
function Write-SSH-Information($sshFolder, $dssHost, $dssUser, $localUser)
{
    # Write key
    $privateKeyFileName = $sshFolder + "\key"
    
    # Open stream
    $stream = [System.IO.StreamWriter] $privateKeyFileName

    # Write the key
    $stream.WriteLine("[PLEASE PASTE THE PRIVATE KEY FOR USER $dssUser HERE!]")

    # Close stream
    $stream.close()

    # Write config file
    $configFileName = $sshFolder + "\config"

    # Open stream
    $stream = [System.IO.StreamWriter] $configFileName

    # Path to the key to save in the config file
    $privateKeyFileNamePosix = "/home/$localUser/.ssh/key"

    # Write the server configuration
    $stream.WriteLine("Host $dssHost");
    $stream.WriteLine("    HostName $dssHost");
    $stream.WriteLine("    User $dssUser");
    $stream.WriteLine("    IdentityFile $privateKeyFileNamePosix");

    # Close stream
    $stream.close()

    # Write known_hosts file
    $configFileName = $sshFolder + "\known_hosts"

    # Open stream
    $stream = [System.IO.StreamWriter] $configFileName

    # Close stream
    $stream.close()

}

# Write the settings to a JSON File.
# Uses global variables.
function Write-Settings($settingsFileName) {

    # Check and add extension if needed
    if (! $summaryFileName.EndsWith(".json")) {
        $summaryFileName = $summaryFileName + ".json"
    }

    # Write the summary
    $settings = @{
        computer_name              = $env:COMPUTERNAME;
        computer_friendly_name     = $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME;
        installation_dir           = $INSTALL_DIR;
        use_existing_java          = $SYSTEM_JAVA;
        java_path                  = $FINAL_JRE_PATH;
        user_folder                = $USER_FOLDER;
        datamover_data_folder      = $DATAMOVER_DATA_FOLDER;
        datamover_service_name     = $DATAMOVER_SERVICE_NAME;
        local_user                 = $LOCAL_USER;
        openbis_host               = $OPENBIS_HOST;
        openbis_host_port          = $OPENBIS_PORT;
        datastore_host             = $DSS_HOST;
        datastore_user             = $DSS_USER;
        datastore_dropbox_path     = $DSS_DROPBOX_PATH;
        datastore_lastchanged_path = $DSS_LASTCHANGED_PATH;
        annotation_tool_acq_type   = $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE;
        accept_self_signed_certs   = $ACCEPT_SELF_SIGNED_CERTIFICATES;
        platform_bits              = $PLATFORM_N_BITS;
        }

    # Create JSON file
    $settings | ConvertTo-Json -depth 999 | Out-File $settingsFileName
}

# Read settings from JSON file and return a Powershell hashtable.
function Read-Settings($settingsFileName) {

    # Read and convert the JSON file
    $json = Get-Content -Raw -Path $settingsFileName | ConvertFrom-Json

    # COnvert the Powershell object to a hashtable
    $settings = @{}
    $json.json.properties | Foreach { $ht[$_.Name] = $_.Value }

    # Return the object
    return $settings
}

# Write a summary of all settings in human-friendly form
# Uses global variables
function Write-SettingsSummary($summaryFileName)
{   
    # Open stream
    $stream = [System.IO.StreamWriter] $summaryFileName

    # Write the summary
    $stream.WriteLine("[Hardware]")
    $stream.WriteLine("Computer name                       : $env:COMPUTERNAME")
    $stream.WriteLine("Acquisition machine                 : $ANNOTATION_TOOL_ADMIN_ACQUISITION_FRIENDLY_NAME")
    $stream.WriteLine("Lab                                 : <please fill in for your records>")
    $stream.WriteLine("")
    $stream.WriteLine("[Settings]")
    $stream.WriteLine("")
    $stream.WriteLine("Installation dir                    : $INSTALL_DIR")
    $stream.WriteLine("Using existing JAVA installation    : $SYSTEM_JAVA")
    $stream.WriteLine("JAVA runtime in use                 : $FINAL_JRE_PATH")
    $stream.WriteLine("")
    $stream.WriteLine("User folder                         : $USER_FOLDER")
    $stream.WriteLine("Datamover data folder               : $DATAMOVER_DATA_FOLDER")
    $stream.WriteLine("Datamover service name              : $DATAMOVER_SERVICE_NAME")
    $stream.WriteLine("Local user                          : $LOCAL_USER")
    $stream.WriteLine("")
    $stream.WriteLine("openBIS host                        : $OPENBIS_HOST")
    $stream.WriteLine("openBIS host port                   : $OPENBIS_PORT")
    $stream.WriteLine("")
    $stream.WriteLine("Datastore server                    : $DSS_HOST")
    $stream.WriteLine("Datastore server user               : $DSS_USER")
    $stream.WriteLine("Datastore server dropbox path       : $DSS_DROPBOX_PATH")
    $stream.WriteLine("Datastore server 'lastchanged' path : $DSS_LASTCHANGED_PATH")
    $stream.WriteLine("")
    $stream.WriteLine("Annotation Tool acquisition type    : $ANNOTATION_TOOL_ADMIN_ACQUISITION_TYPE")
    $stream.WriteLine("Accept self-signed certificates     : $ACCEPT_SELF_SIGNED_CERTIFICATES")

    $stream.WriteLine("")
    $stream.WriteLine("[Generated configuration files]")
    $stream.WriteLine("")
    $stream.WriteLine("Datamover JSL                       : $INSTALL_DIR\obit_datamover_jsl\jsl_static.ini")
    $stream.WriteLine("Datamover                           : $INSTALL_DIR\obit_datamover_jsl\datamover\etc\service.properties")
    $stream.WriteLine("Annotation Tool                     : $INSTALL_DIR\obit_annotation_tool\AnnotationTool.ini")
    $stream.WriteLine("Annotation Tool Admin               : $INSTALL_DIR\obit_annotation_tool\AnnotationToolAdmin.ini")
    $stream.WriteLine("SSH key and config (secret!)        : $INSTALL_DIR\obit_datamover_jsl\datamover\bin\home\$LOCAL_USER\.ssh")

    $stream.WriteLine("")
    $stream.WriteLine("[Downloaded/used components]")
    $stream.WriteLine("")
    $stream.WriteLine("Platform                            : $PLATFORM_N_BITS bits")
    $stream.WriteLine("Datamover JSL                       : $DATAMOVER_JSL_URL")
    $stream.WriteLine("Datamover                           : $DATAMOVER_URL")
    $stream.WriteLine("Annotation Tool                     : $OBIT_ANNOTATION_TOOL_URL")
    $stream.WriteLine("JAVA Runtime                        : $JAVA_URL")

    $stream.WriteLine("")
    $stream.WriteLine("[Comments]")
    $stream.WriteLine("<please fill in for your records>")

    # Close stream
    $stream.close()

}


# Write a summary of all settings to Desktop
# Uses global variables
function read-SettingsSummary($summaryFileName) {   

    # Build regular expression
    $regex = '^(.*)\s*:\s(\w*)$'

    # Dictionary of settings
    $SETTINGS = @{}

    # Open stream
    $reader = [System.IO.File]::OpenText($summaryFileName)
    while ($null -ne ($line = $reader.ReadLine())) {

        # Process current line
        if ($line -match $regex) {

            $key = $matches[1].TrimEnd()
            $value = $matches[2]

            $SETTINGS.Add($key, $value)

        }
    }

    # Return the dictionary
    return $SETTINGS
}
