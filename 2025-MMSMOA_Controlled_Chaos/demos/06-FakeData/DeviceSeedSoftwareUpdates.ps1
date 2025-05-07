# Define the site code, SMS provider machine name, and SQL server instance details
$SiteCode = '' # Site code 
$ProviderMachineName = '' # SMS Provider machine name
$sqlServerInstance = '' # CM Server / instance
$database = "CM_$SiteCode" # CM Database
$FakeDevicePrefix = '' # The script assumes you named all your fake devices with a specific prefix

# Initialize parameters for importing the ConfigurationManager module
$initParams = @{}

# Import the ConfigurationManager.psd1 module if not already imported
if ((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to the site code drive
Set-Location "$($SiteCode):\" @initParams

# SQL query to retrieve fake device information from the Configuration Manager database
$query = @"
    SELECT 
        sys.ResourceID AS 'ResourceID',
        sys.Name0 AS 'Device',
        sys.Client_Version0 AS 'ClientVersion',
        sys.SMS_Unique_Identifier0 AS 'SMSID',
        os.Caption0 AS 'OperatingSystem'
    FROM 
        v_R_System sys
    JOIN 
        v_GS_OPERATING_SYSTEM os ON sys.ResourceID = os.ResourceID
    WHERE
        sys.Name0 LIKE '{0}%'
"@ -f $FakeDevicePrefix

# Execute the query to retrieve all fake device information
$FakeDevices = Invoke-Sqlcmd -ServerInstance $sqlServerInstance -Database $database -Query $query

# Grab all software updates that are security updates and aren't expired or superseded. Wanted to do this with sql but the software update tables give me sadness
$SoftwareUpdates = Get-CMSoftwareUpdate -Fast -IsExpired:$false -IsSuperseded:$false -CategoryName "Security Updates"

# Populate variables filled with the updates per operating system
$Windows10Updates = $SoftwareUpdates | Where-Object { $_.LocalizedCategoryInstanceNames -like 'Windows 10*' -and $_.LocalizedDisplayName -notlike '*ARM64*' -and $_.LocalizedDisplayName -notlike '*x86*' } 
$Windows11Updates = $SoftwareUpdates | Where-Object { $_.LocalizedCategoryInstanceNames -like 'Windows 11*' -and $_.LocalizedDisplayName -notlike '*ARM64*' -and $_.LocalizedDisplayName -notlike '*x86*' } 
$WindowsServer2012Updates = $SoftwareUpdates | Where-Object { $_.LocalizedCategoryInstanceNames -like 'Windows Server 2012*' }
$WindowsServer2016Updates = $SoftwareUpdates | Where-Object { $_.LocalizedCategoryInstanceNames -like 'Windows Server 2016*' }  
$WindowsServer2019Updates = $SoftwareUpdates | Where-Object { $_.LocalizedCategoryInstanceNames -like 'Windows Server 2019*' }  
$WindowsServer2022Updates = $SoftwareUpdates | Where-Object { $_.LocalizedCategoryInstanceNames -like 'Microsoft Server operating system-21H2*' }

foreach ($FakeDevice in $FakeDevices) {
    $null = $ApplicableUpdates

    # Find which suite of updates are applicable based on the operating system
    $ApplicableUpdates = switch -Wildcard ($FakeDevice.OperatingSystem) {
        'Microsoft Windows 10*' { $Windows10Updates }
        'Microsoft Windows 11*' { $Windows11Updates }
        'Microsoft Windows Server 2012*' { $WindowsServer2012Updates }
        'Microsoft Windows Server 2016*' { $WindowsServer2016Updates }
        'Microsoft Windows Server 2019*' { $WindowsServer2019Updates }
        'Microsoft Windows Server 2022*' { $WindowsServer2022Updates }
        Default {}
    }

    # If any updates are found, begin building a state message
    if ($ApplicableUpdates) {
        # Dont "fix" the indenting of the state message, powershell exports it odd and breaks the output
        $StateMessage = @"
<?xml version="1.0" encoding="UTF-16"?>
<Report>
    <ReportHeader>
        <Identification>
            <Machine>
                <ClientInstalled>1</ClientInstalled>
                <ClientType>1</ClientType>
                <ClientID>$($FakeDevice.SMSID)</ClientID>
                <ClientVersion>$($FakeDevice.ClientVersion)</ClientVersion>
                <NetBIOSName>$($FakeDevice.Device)</NetBIOSName>
                <CodePage>437</CodePage>
                <SystemDefaultLCID>1033</SystemDefaultLCID>
                <Priority>10</Priority>
            </Machine>
        </Identification>
        <ReportDetails>
            <ReportContent>State Message Data</ReportContent>
            <ReportType>Full</ReportType>
            <Date>$((Get-Date).ToString("yyyyMMddHHmmss.ffffff+000"))</Date>
            <Version>1.0</Version>
            <Format>1.0</Format>
        </ReportDetails>
    </ReportHeader>
    <ReportBody>
"@
        foreach ($Update in $ApplicableUpdates) {
            # Wanted some devices to show as always compliant, some to show as totally noncompliant, and some to have a mixture of some compliant updates and some noncompliant. 
            # To do this, grabbing the last digit of the device name and making some decisions based off what it is
            $lastDigit = $($FakeDevice.Device).Substring($($FakeDevice.Device).Length - 1)
            ##TODO Parameterize this
            if ($lastDigit -ge 0 -and $lastDigit -lt 5){
                # Compliant
                $StateID = 3
            }
            elseif ($lastDigit -eq 9){
                # Non-Compliant
                $StateID = 2
            }
            else{
                #Random compliance
                $StateID = 2, 3 | Get-Random
            }

            # Append State info
            # Dont "fix" the indenting of the state message, powershell exports it odd and breaks the output
            $UpdateStateMessage = @"

    <StateMessage MessageTime="$((Get-Date).ToString("yyyyMMddHHmmss.ffffff+000"))" SerialNumber="5001">
        <Topic ID="$($Update.CI_UniqueID)" Type="500" IDType="3" User="" UserSID=""/>
        <State ID="$($StateID)" Criticality="0"/>
        <UserParameters Flags="0" Count="1">
            <Param>200</Param>
        </UserParameters>
    </StateMessage>
"@
            $StateMessage = $StateMessage + $UpdateStateMessage
        }

        # Dont "fix" the indenting of the state message, powershell exports it odd and breaks the output
        $StateMessage = $StateMessage + @"

    </ReportBody>
</Report>
"@

        #Write to mp inbox
        Out-File -InputObject $StateMessage -FilePath "D:\Program Files\Microsoft Configuration Manager\inboxes\auth\statesys.box\incoming\$($FakeDevice.Device).smx"
    }
}
