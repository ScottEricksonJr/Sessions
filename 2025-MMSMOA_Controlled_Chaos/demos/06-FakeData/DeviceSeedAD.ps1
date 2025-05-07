## 100% unapologetically vibe coded.
# Prompt the user for the number of computer objects to create, the OU, and a prefix for device names
param (
    [int]$NumberOfComputers = (Read-Host "Enter the number of computer objects to create"),
    [string]$BaseOU = (Read-Host "Enter the base OU (e.g., OU=Computers,DC=example,DC=com)"),
    [string]$DevicePrefix = (Read-Host "Enter a prefix for the device names")
)

# Define a list of departments for dynamic OU creation
$Departments = @('Finance', 'Sales', 'Engineering', 'Human Resources', 'Marketing', 'IT Support', 'Operations', 'Legal', 'Customer Service', 'Research and Development')

# Define a list of operating systems and their versions
$OperatingSystems = @(
    @{ OS = 'Windows 10'; Version = '10.0.19042' },
    @{ OS = 'Windows 11'; Version = '10.0.22000' },
    @{ OS = 'Windows Server 2019'; Version = '10.0.17763' },
    @{ OS = 'Windows Server 2022'; Version = '10.0.20348' }
)

# Function to create a random computer name
function Generate-RandomComputerName {
    param (
        [int]$Length = 12 # Default length of the computer name
    )
    # Initialize the character arrays
    $chars = @()
    $tokenChars = @()

    # Add uppercase letters
    65..90 | ForEach-Object { $chars += [char]$_ }
    # Add digits
    48..57 | ForEach-Object { $chars += [char]$_ }

        # Generate a random 12-digit number as the computer name
    -join (Get-Random -Count $Length -InputObject $chars)
}

function Generate-RandomLAPSPassword {
    param (
        [int]$PasswordLength = 12,
        [int]$TokenLength = 14
    )

    # Initialize the character arrays
    $chars = @()
    $tokenChars = @()

    # Add uppercase letters
    65..90 | ForEach-Object { $chars += [char]$_ }
    # Add lowercase letters
    97..122 | ForEach-Object { $chars += [char]$_ }
    # Add digits
    48..57 | ForEach-Object { $chars += [char]$_ }
    # Add special characters
    $chars += '!','@','#','$','%','^','&','*','(',')'

    # Generate password
    $password = -join (Get-Random -Count $PasswordLength -InputObject $chars)

    # Add hexadecimal characters for token
    97..102 | ForEach-Object { $tokenChars += [char]$_ }
    48..57 | ForEach-Object { $tokenChars += [char]$_ }

    # Generate token
    $token = -join (Get-Random -Count $TokenLength -InputObject $tokenChars)

    # Create the output object
    $lapsObject = @{
        n = "LAPSAdmin"
        t = $token
        p = $password
    }

    # Return the object as JSON
    return ($lapsObject | ConvertTo-Json -Depth 1)
}


# Function to generate a random LAPS password expiration time
function Generate-RandomLAPSExpirationTime {
    param (
        [datetime]$BaseDate = (Get-Date),
        [int]$DaysToAdd = (Get-Random -Minimum 1 -Maximum 30) # Random expiration within 1-30 days
    )

    $ExpirationDate = $BaseDate.AddDays($DaysToAdd)
    [long]::Parse($ExpirationDate.ToFileTimeUtc())
}

# Loop to create the specified number of computer objects
for ($i = 1; $i -le $NumberOfComputers; $i++) {
    # Generate a random computer name with the specified prefix
    $ComputerName = "$DevicePrefix$(Generate-RandomComputerName)"

    # Randomly decide on a department and create a dynamic OU
    $Department = $Departments | Get-Random
    $OU = "OU=$Department,$BaseOU"

    # Ensure the dynamic OU exists
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OU'")) {
        New-ADOrganizationalUnit -Name $Department -Path $BaseOU
    }

    # Create the computer object in Active Directory
    New-ADComputer -Name $ComputerName -Path $OU

    # Randomly assign extension attributes for LAPS and BitLocker
    $HasLAPS = (Get-Random -Minimum 0 -Maximum 2) -eq 1
    $HasBitLocker = (Get-Random -Minimum 0 -Maximum 2) -eq 1

    # Randomly select an operating system and version
    $SelectedOS = $OperatingSystems | Get-Random
    $OperatingSystem = $SelectedOS.OS
    $OperatingSystemVersion = $SelectedOS.Version

    if ($HasLAPS) {
        $LAPSObject = Generate-RandomLAPSPassword | ConvertFrom-Json
        $LAPSJsonString = "{""n"":""$($LAPSObject.n)"",""t"":""$($LAPSObject.t)"",""p"":""$($LAPSObject.p)""}"
        $LAPSExpirationTime = Generate-RandomLAPSExpirationTime
        Set-ADComputer -Identity $ComputerName -Add @{
            'msLAPS-Password' = $LAPSJsonString;
            'msLAPS-PasswordExpirationTime' = $LAPSExpirationTime
        }
    }

    if ($HasBitLocker) {
        $BitLockerKey = (Get-Random -Minimum 1000000000000000 -Maximum 9999999999999999).ToString()
        # Generate a unique GUID for the msFVE-RecoveryGuid and msFVE-VolumeGuid attributes
        $RecoveryGuid = [guid]::NewGuid().ToString()
        $VolumeGuid = [guid]::NewGuid().ToString()

        # Generate a timestamped name for the msFVE-RecoveryInformation object
        $Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
        $RecoveryObjectName = "$Timestamp{$RecoveryGuid}"

        # Create the msFVE-RecoveryInformation child object with required attributes
        $RecoveryInfo = New-ADObject -Name $RecoveryObjectName -Type "msFVE-RecoveryInformation" -Path "CN=$ComputerName,$OU" -OtherAttributes @{
            'msFVE-RecoveryGuid' = $RecoveryGuid;
            'msFVE-VolumeGuid' = $VolumeGuid;
            'msFVE-RecoveryPassword' = $BitLockerKey
        }
    }

    # Set the operating system and version attributes
    Set-ADComputer -Identity $ComputerName -Add @{
        'OperatingSystem' = $OperatingSystem;
        'OperatingSystemVersion' = $OperatingSystemVersion
    }

    Write-Host "Created computer object: $ComputerName in OU: $OU with LAPS: $HasLAPS, BitLocker: $HasBitLocker, OS: $OperatingSystem, Version: $OperatingSystemVersion"
}