## 100% unapologetically vibe coded.

# Prompt the user for the number of user objects to create and the base OU
param (
    [int]$NumberOfUsers = (Read-Host "Enter the number of user objects to create"),
    [string]$BaseOU = (Read-Host "Enter the base OU (e.g., OU=Users,DC=example,DC=com)")
)

# Define a list of departments for dynamic OU assignment
$Departments = @('Finance', 'Sales', 'Engineering', 'Human Resources', 'Marketing', 'IT Support', 'Operations', 'Legal', 'Customer Service', 'Research and Development')

# Define a list of job titles for random assignment
$JobTitles = @('Software Engineer', 'Sales Manager', 'HR Specialist', 'Marketing Coordinator', 'IT Support Technician', 'Operations Analyst', 'Legal Advisor', 'Customer Service Representative', 'Research Scientist', 'Financial Analyst')

# Predefined list of first and last names
$FirstNames = @('James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen', 'Christopher', 'Nancy', 'Daniel', 'Lisa', 'Matthew', 'Betty', 'Anthony', 'Margaret', 'Mark', 'Sandra', 'Donald', 'Ashley', 'Paul', 'Kimberly', 'Steven', 'Emily', 'Andrew', 'Donna', 'Kenneth', 'Michelle', 'George', 'Dorothy', 'Joshua', 'Carol', 'Kevin', 'Amanda', 'Brian', 'Melissa')
$LastNames = @('Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores', 'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts')

# Function to fetch random names from the predefined list
function Get-RandomName {
    $firstName = $FirstNames | Get-Random
    $lastName = $LastNames | Get-Random
    return @{ FirstName = $firstName; LastName = $lastName }
}

# Loop to create the specified number of user objects
for ($i = 1; $i -le $NumberOfUsers; $i++) {
    # Fetch a random name
    $Name = Get-RandomName
    $FirstName = $Name.FirstName
    $LastName = $Name.LastName

    # Generate email and username in firstname.lastname format
    $Email = "$FirstName.$LastName@example.com"
    $Username = "$FirstName.$LastName"

    # Randomly decide on a department and create a dynamic OU
    $Department = $Departments | Get-Random
    $OU = "OU=$Department,$BaseOU"

    # Ensure the dynamic OU exists
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OU'")) {
        New-ADOrganizationalUnit -Name $Department -Path $BaseOU
    }

    # Assign a random job title
    $JobTitle = $JobTitles | Get-Random

    # Create the user object in Active Directory
    New-ADUser -Name "$FirstName $LastName" -GivenName $FirstName -Surname $LastName -UserPrincipalName "$Username@example.com" -SamAccountName $Username -EmailAddress $Email -Path $OU -Title $JobTitle -Department $Department -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true

    Write-Host "Created user object: $FirstName $LastName in OU: $OU with email: $Email, username: $Username, job title: $JobTitle, and department: $Department"
}