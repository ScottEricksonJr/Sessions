# This script is designed to seed devices into Intune with randomized attributes.
# It uses the AADInternals module to perform operations such as joining devices to Azure AD and Intune.

param (
    [int]$NumberOfDevices = 15, # Number of devices to create (default: 15)
    [int]$StartingNumber = 1,   # Starting number for device naming (default: 1)
    [string]$ModulePath = "C:\Program Files\WindowsPowerShell\Modules\AADInternals\2.0.0\AADInternals.psd1" # Path to the AADInternals module
    [string]$FakeDevicePrefix = "FD" # Prefix for device names (default: "Device")
)

# Import the AADInternals module
Import-Module $ModulePath

# Obtain access tokens for Azure AD and Intune operations
Get-AADIntAccessTokenForAADGraph -Resource urn:ms-drs:enterpriseregistration.windows.net -SaveToCache
$bprt = New-AADIntBulkPRTToken -Name "My BPRT user"

# Get an access token for AAD join and save it to the cache
Get-AADIntAccessTokenForAADJoin -SaveToCache -BPRT $bprt

# Define a mapping of manufacturers to their models and device types
$DeviceManufacturerModels = @{
    'Microsoft Corporation' = @(
        @{ Model = 'Surface Pro'; Type = 'Tablet' },
        @{ Model = 'Surface Laptop'; Type = 'Laptop' },
        @{ Model = 'Surface Studio'; Type = 'Desktop' },
        @{ Model = 'Surface Book'; Type = 'Laptop' }
    );
    'Dell Inc.' = @(
        @{ Model = 'Latitude'; Type = 'Laptop' },
        @{ Model = 'XPS'; Type = 'Laptop' },
        @{ Model = 'Inspiron'; Type = 'Laptop' },
        @{ Model = 'Precision'; Type = 'Workstation' }
    );
    'HP Inc.' = @(
        @{ Model = 'EliteBook'; Type = 'Laptop' },
        @{ Model = 'ProBook'; Type = 'Laptop' },
        @{ Model = 'Spectre'; Type = 'Laptop' },
        @{ Model = 'Pavilion'; Type = 'Laptop' }
    );
    'Lenovo' = @(
        @{ Model = 'ThinkPad'; Type = 'Laptop' },
        @{ Model = 'IdeaPad'; Type = 'Laptop' },
        @{ Model = 'Yoga'; Type = 'Convertible' },
        @{ Model = 'Legion'; Type = 'Gaming' }
    );
}

# Define arrays for other dynamic parameters
$DeviceModelVersions = @('1.3', '2.0', '3.1', '4.0')
$DeviceLanguages = @('en-US', 'fr-FR', 'es-ES', 'de-DE')
$OSPlatforms = @('Windows 10 Enterprise', 'Windows 11 Pro', 'Windows 10 Pro')
$OSVersions = @('10.0.18363.1016', '10.0.19042.928', '11.0.22000.318')
$FWVersions = @('Hyper-V UEFI Release v4.0', 'BIOS v1.2', 'UEFI v2.3')
$HWVersions = @('Hyper-V UEFI Release v4.0', 'BIOS v1.2', 'UEFI v2.3')
$OEMs = @('Microsoft Corporation', 'Dell Inc.', 'HP Inc.', 'Lenovo')

# Define options for RAM, storage, and free space (all in MB)
$RAMOptions = @(4096, 8192, 16384, 32768, 65536)
$StorageOptions = @(131072, 262144, 524288, 1048576, 2097152)
$FreeSpaceOptions = @(10240, 20480, 51200, 102400, 204800, 512000)

# Function to generate a random serial number in the specific numeric format
function New-RandomSerialNumber {
    param (
        [int]$SegmentLength = 4, # Length of each segment
        [int]$SegmentCount = 7  # Number of segments
    )

    # Generate segments of random numbers and join them with dashes
    $segments = for ($i = 0; $i -lt $SegmentCount; $i++) {
        -join (Get-Random -Count $SegmentLength -InputObject (0..9))
    }
    $segments -join '-'
}

# Loop to create the specified number of devices
for ($i = $StartingNumber; $i -lt ($StartingNumber + $NumberOfDevices); $i++) {
    # Generate a device name using the starting number and prefix
    $deviceName = "$FakeDevicePrefix{0:D4}" -f $i

    # Join the device to Azure AD and capture the information stream
    Join-AADIntDeviceToAzureAD -DeviceName $deviceName -DeviceType "Windows" -OSVersion "11" -InformationVariable infovar
    $infoText = ($infovar.MessageData.Message -join "`n")

    # Extract the certificate file name using regex
    if ($infoText -match 'Cert file name\s*:\s*"(?<CertFileName>[^"]+)"') {
        $certFileName = $matches['CertFileName']
    }

    # Get an access token for Intune MDM and save it to the cache
    Get-AADIntAccessTokenForIntuneMDM -SaveToCache -PfxFileName ".\$certfilename" -BPRT $bprt

    # Join the device to Intune and capture the information stream
    Join-AADIntDeviceToIntune -DeviceName $deviceName -InformationVariable infovar
    $infoText = ($infovar.MessageData.Message -join "`n")

    # Extract the certificate file name using regex
    if ($infoText -match 'Cert file name\s*:\s*"(?<CertFileName>[^"]+)"') {
        $certFileName = $matches['CertFileName']
    }

    # Randomly select a manufacturer and model
    $DeviceManufacturer = $DeviceManufacturerModels.Keys | Get-Random
    $ModelDetails = $DeviceManufacturerModels[$DeviceManufacturer] | Get-Random

    # Extract model and type from the selected details
    $DeviceModel = $ModelDetails.Model
    $DeviceType = $ModelDetails.Type

    # Randomly select RAM, storage, and free space
    $DeviceRAM = $RAMOptions | Get-Random
    $DeviceStorage = $StorageOptions | Get-Random
    $FreeSpace = $FreeSpaceOptions | Get-Random

    # Generate a random serial number
    $SerialNumber = New-RandomSerialNumber

    # Define parameters for the callback
    $params = @{
        PfxFileName = $certFileName

        ## Device information
        DeviceName = $deviceName
        DeviceManufacturer = $DeviceManufacturer
        DeviceModel = $DeviceModel
        DeviceModelVersion = $DeviceModelVersions | Get-Random
        DeviceLanguage = $DeviceLanguages | Get-Random
    
        ## OS information
        OSPlatform = $OSPlatforms | Get-Random
        OSVersion = $OSVersions | Get-Random
        DomainName = ''
    
        ## Hardware information
        FWVersion = $FWVersions | Get-Random
        HWVersion = $HWVersions | Get-Random
        OEM = $OEMs | Get-Random
        DeviceType = $DeviceType
        ProcessorArchitecture = 9
        ProcessorType = 8664
        TotalRam = $DeviceRAM
        TotalStorage = $DeviceStorage
        SMBiosSerialNumber = $SerialNumber
    }

    # Start the callback to Intune with the generated parameters
    Start-AADIntDeviceIntuneCallback @params
}