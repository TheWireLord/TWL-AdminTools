# This script is used to reset the password for a Gmail user using GAM (Google Apps Manager) command-line tool.
# It prompts the user to enter the first name, last name, or username of the user to reset the password for.
# It then displays a table of matching users and allows the user to select a user to reset the password for.
# The script generates a random password, resets the user's password using GAM, and copies the new password to the clipboard.
# It also logs the password reset action in a log file and allows the user to reset another password if desired.

# Change the console title
$host.UI.RawUI.WindowTitle = "TWL - GOOGLE - PASS"

# Define the log directory and file path
$logDir = "logs"
$logFile = "$logDir/log-GmailPassReset.txt"

# Check if the log directory exists, if not, create it
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir
}

# Add a log entry for the start of the script
Add-Content -Path $logFile -Value ("[GMAIL]-STARTED: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))

# Function to show the title screen
function Show-TitleScreen {
    # Change the console background color
    $host.UI.RawUI.BackgroundColor = "DarkRed"
    
    $title = @"
            TWL - GOOGLE - PASS         

                GGGGGGGGGGGGG           
             GGG::::::::::::G           
           GG:::::::::::::::G           
          G:::::GGGGGGGG::::G           
         G:::::G       GGGGGG           
        G:::::G                         
        G:::::G                         
        G:::::G    GGGGGGGGGG           
        G:::::G    G::::::::G           
        G:::::G    GGGGG::::G           
        G:::::G        G::::G           
         G:::::G       G::::G           
          G:::::GGGGGGGG::::G           
           GG:::::::::::::::G           
             GGG::::::GGG:::G           
                GGGGGG   GGGG           

"@
    Write-Host $title

    # Change the console background color
    $host.UI.RawUI.BackgroundColor = "Black"
}

# Function to get users table
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

# Function to reset password
function Reset-Password {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$selectedUser
    )

    # Generate a random password
    $wordList = @('Frog', 'Hop', 'Leap', 'Pond', 'Log', 'Track', 'Pop', 'Otter', 'Grass', 'Rocket', 'Loop', 'Bop', 'Pull', 'Flight', 'World', 'Music', 'Honey', 'Otter', 'Slap', 'Glare', 'Bad', 'Good', 'Ramp', 'Glide', 'Bear', 'Arm', 'Apple', 'Pear', 'Peach', 'Age', 'Brand', 'Bend', 'Cloud', 'Truck', 'Car', 'Lake', 'Sea')
    $randomWords = (Get-Random -InputObject $wordList -Count 2 | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) })
    $randomNumber = Get-Random -Minimum 1000 -Maximum 9999
    $randomPassword = ($randomWords -join "") + "@" + $randomNumber

    # Reset the user's password using GAM
    & gam update user $selectedUser.Username password $randomPassword changepassword on

    # Add a log entry for the password reset
    Add-Content -Path $logFile -Value ("USER: $($selectedUser.Username) Reset At: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))

    # Copy the password to the clipboard
    $randomPassword | Set-Clipboard

    # Change background color
    $host.UI.RawUI.BackgroundColor = "DarkGreen"

    # Output the new password
    Write-Host "The password for user $($selectedUser.Username) has been reset and copied to the clipboard."
    
    # Change background color
    $host.UI.RawUI.BackgroundColor = "Black"
}

# Function to restart the script
function Restart-Script {
    & $PSScriptRoot\twlGooglePassReset.ps1
}

# Function to close the script
function Close-Script {
    # Add a log entry for the end of the script
    Add-Content -Path $logFile -Value ("END: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))
    exit
}

# Show the title screen
Show-TitleScreen

# Prompt the user to enter the first name, last name, or username
$searchQuery = Read-Host "Enter the first name, last name, or username of the user to reset the password for"

# Add a log entry for the search query
Add-Content -Path $logFile -Value ("SEARCH: $searchQuery At: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))

# Get the initial users table
$usersTable = @(Get-UsersTable -searchQuery $searchQuery)

# Display the users table
$usersTable | Format-Table -AutoSize

# Prompt the user to select the number of the user to reset the password for or to get more info
$choice = Read-Host "Enter the number of the user to reset the password for, or enter 'info' to get more information about all users"

if ($choice -eq 'info') {
    # Get more info about all users
    $usersTable = @(Get-UsersTable -searchQuery $searchQuery -detailedInfo $true)
    $usersTable | Format-Table -AutoSize

    # Prompt the user to select the number of the user to reset the password for
    $choice = Read-Host "Enter the number of the user to reset the password for"
}

if ($choice -match '^\d+$' -and $choice -le $usersTable.Count) {
    # Reset the password for the selected user
    $selectedUser = $usersTable | Where-Object { $_.Number -eq $choice }
    Reset-Password -selectedUser $selectedUser

    # Ask the user if they want to reset another password
    $resetAnother = Read-Host "Do you want to reset another password? (Y/N)"
    if ($resetAnother -eq 'Y') {
        # Restart the script
        Restart-Script
    } else {
        # Close the script
        Close-Script
    }

} else {
    Write-Host "Invalid input. Please run the script again..."

    # Ask the user if they want to run the script again
    $runAgain = Read-Host "Do you want to run the script again? (Y/N)"
    if ($runAgain -eq 'Y') {
        # Restart the script
        Restart-Script
    } else {
        # Close the script
        Close-Script
    }
}