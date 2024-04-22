function Get-UsersTable {
    param(
        [Parameter(Mandatory=$true)]
        [string]$searchQuery,
        [Parameter(Mandatory=$false)]
        [bool]$detailedInfo = $false
    )

    # Define the fields to retrieve based on whether detailed info is requested
    $fields = if ($detailedInfo) { "primaryEmail,lastLoginTime,creationTime,orgUnitPath" } else { "primaryEmail" }

    # Search for the Gmail user based on the search query
    $usersCsv = & gam print users query "$searchQuery" fields $fields | Out-String
    $users = $usersCsv | ConvertFrom-Csv

    # Display the users in a table and assign each user to a number
    $index = 1
    $usersTable = @()
    $users | ForEach-Object {
        $user = $_
        $username = $user.'primaryEmail'.Split('@')[0] # Extract the username from the email

        $isSuspended = if ($detailedInfo) {
            # Get the user info
            $userInfo = & gam info user $user.'primaryEmail' | Out-String
            # Extract the isSuspended field
            if ($userInfo -match 'Suspended: (.*)') {
                $Matches[1]
            } else {
                'Unknown'
            }
        }

        $usersTable += if ($detailedInfo) {
            [PSCustomObject]@{
                Number = $index
                Username = $username
                Email = $user.'primaryEmail'
                LastLoginTime = $user.'lastLoginTime'
                CreationTime = $user.'creationTime'
                OrgUnitPath = $user.'orgUnitPath'
                IsLockedOut = $isSuspended
            }
        } else {
            [PSCustomObject]@{
                Number = $index
                Username = $username
            }
        }
        $index++
    }
    $usersTable
}

# Prompt the user to enter the first name, last name, or username
$searchQuery = Read-Host "Enter the first name, last name, or username of the user to reset the password for"

# Get the initial users table
$usersTable = Get-UsersTable -searchQuery $searchQuery

# Display the users table
$usersTable | Format-Table -AutoSize

# Prompt the user to select the number of the user to reset the password for or to get more info
$choice = Read-Host "Enter the number of the user to reset the password for, or enter 'info' to get more information about all users"

if ($choice -eq 'info') {
    # Get more info about all users
    $usersTable = Get-UsersTable -searchQuery $searchQuery -detailedInfo $true
    $usersTable | Format-Table -AutoSize

    # Prompt the user to select the number of the user to reset the password for
    $choice = Read-Host "Enter the number of the user to reset the password for"
}

if ($choice -match '^\d+$' -and $choice -le $usersTable.Count) {
    # Reset the password for the selected user
    $selectedUser = $usersTable | Where-Object { $_.Number -eq $choice }

    # Generate a random password
    $wordList = @("apple", "banana", "cherry", "date", "elderberry", "fig", "grape", "honeydew", "kiwi", "lemon")
    $randomWords = (Get-Random -InputObject $wordList -Count 2 | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) })
    $randomNumber = Get-Random -Minimum 1000 -Maximum 9999
    $randomPassword = ($randomWords -join "") + "@" + $randomNumber

    # Reset the user's password using GAM
    & gam update user $selectedUser.Username password $randomPassword changepassword on

    # Copy the password to the clipboard
    $randomPassword | Set-Clipboard

    # Output the new password
    Write-Host "The password for user $($selectedUser.Username) has been reset and copied to the clipboard."
} else {
    Write-Host "Invalid input. Please run the script again and select a valid user or enter 'info'."
}