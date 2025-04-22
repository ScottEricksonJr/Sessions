# Parameters for the script
param (
    [string]$SiteServer,
    [string]$SiteCode,
    [string]$Property = "Priority",
    [string]$TargetDp,
    [int]$PriorityValue = 200 ## Default value for all DPs is 200. Lower the number, higher the priority.
)

# Function to update DP priority
function Update-DpPriority {
    try {
        # Connect to CIM
        $namespace = "root/sms/site_$SiteCode"
        $query = "SELECT * FROM SMS_SCI_SysResUse WHERE RoleName = 'SMS Distribution Point' AND NetworkOSPath = '\\$TargetDp'"
        $dp = Get-CimInstance -ComputerName $SiteServer -Namespace $namespace -Query $query

        if (-not $dp) {
            Write-Error "Distribution Point not found for TargetDp: $TargetDp"
            return
        }

        # Find the property to update
        $props = $dp.Props
        $prop = $props | Where-Object { $_.PropertyName -eq $Property }

        if (-not $prop) {
            Write-Error "Property '$Property' not found on the Distribution Point."
            return
        }

        # Display current priority
        Write-Output "Current Distribution Point Priority: $($prop.Value)"

        # Update the priority
        $prop.Value = $PriorityValue
        Write-Output "Updating the Distribution Point Priority to: $PriorityValue"

        # Save changes
        $dp.Props = $props
        Set-CimInstance -InputObject $dp

        Write-Output "Priority updated successfully."
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Call the function
Update-DpPriority