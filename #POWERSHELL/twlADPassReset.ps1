# This script resets Active Directory user passwords. It prompts for search criteria, finds matching users, and allows selection of a user. 
# It generates a random password, resets the selected user's password, unlocks the account, and copies the new password to the clipboard. 
# It repeats until the user chooses to stop.

# Change the console title
$host.UI.RawUI.WindowTitle = "TWL - AD - PASS"

# Define the log directory and file path
$logDir = "logs"
$logFile = "$logDir/log-ADPassReset.txt"

# Check if the log directory exists, if not, create it
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir
}

# Add a log entry for the start of the script
Add-Content -Path $logFile -Value ("[AD]-STARTED: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))

# This function displays a title screen with a specific design
function Show-TitleScreen {
    # Change the console background color
    $host.UI.RawUI.BackgroundColor = "DarkBlue"

    # Define the title text
    $title = @"

                            TWL - AD - PASS                         

                       AAA               DDDDDDDDDDDDD              
                      A:::A              D::::::::::::DDD           
                     A:::::A             D:::::::::::::::DD         
                    A:::::::A            DDD:::::DDDDD:::::D        
                   A:::::::::A             D:::::D    D:::::D       
                  A:::::A:::::A            D:::::D     D:::::D      
                 A:::::A A:::::A           D:::::D     D:::::D      
                A:::::A   A:::::A          D:::::D     D:::::D      
               A:::::A     A:::::A         D:::::D     D:::::D      
              A:::::AAAAAAAAA:::::A        D:::::D     D:::::D      
             A:::::::::::::::::::::A       D:::::D     D:::::D      
            A:::::AAAAAAAAAAAAA:::::A      D:::::D    D:::::D       
           A:::::A             A:::::A   DDD:::::DDDDD:::::D        
          A:::::A               A:::::A  D:::::::::::::::DD         
         A:::::A                 A:::::A D::::::::::::DDD           
        AAAAAAA                   AAAAAAADDDDDDDDDDDDD              

"@

    # Display the title text
    Write-Host $title

    # Change the console background color back to black
    $host.UI.RawUI.BackgroundColor = "Black"
}

# This function retrieves users from Active Directory based on the provided search criteria
function Get-Users($searchCriteria) {
    # Split the search criteria into parts
    $searchParts = $searchCriteria.Split(' ', 2)

    # If there are two parts in the search criteria, search for users that match the given name and surname or the SamAccountName
    # Otherwise, search for users that match the given name, surname, or SamAccountName
    if ($searchParts.Length -eq 2) {
        return Get-ADUser -Filter "GivenName -like '*$($searchParts[0])*' -and Surname -like '*$($searchParts[1])*' -or SamAccountName -like '*$searchCriteria*'" -Properties LockedOut, LastLogonDate, SamAccountName, Name, EmailAddress, whenCreated
    } else {
        return Get-ADUser -Filter "GivenName -like '*$searchCriteria*' -or Surname -like '*$searchCriteria*' -or SamAccountName -like '*$searchCriteria*'" -Properties LockedOut, LastLogonDate, SamAccountName, Name, EmailAddress, whenCreated
    }
}

# This function displays the list of users retrieved from Active Directory
function Display-Users($users) {
    # Display the header
    Write-Host "Found users:"

    # Initialize the counter
    $counter = 0

    # For each user, display their details in a table
    $users | ForEach-Object {
        # Determine if the user is locked out
        $lockedOut = if ($_.LockedOut) { "LOCKED" } else { "NOT" }

        # Determine the last logon date of the user
        $lastLogon = if ($_.LastLogonDate) { $_.LastLogonDate.ToString() } else { "Never logged in" }

        # Determine the creation date of the user
        $created = if ($_.whenCreated) { $_.whenCreated.ToString() } else { "N/A" }

        # Create a custom object with the user's details
        [PSCustomObject]@{
            'Number' = $counter + 1
            'SamAccountName' = $_.SamAccountName
            'Name' = $_.Name
            'Email' = $_.EmailAddress
            'Locked?' = $lockedOut
            'Created On' = $created
            'Last Logon' = $lastLogon
        }

        # Increment the counter
        $counter++
    } | Format-Table -AutoSize  # Format the output as a table
}

# This function prompts the user to enter the number of the user they want to change the password for
function Get-UserNumber($usersCount) {
    # Loop until a valid user number is entered
    while ($true) {
        # Prompt the user to enter a number
        $userNumber = Read-Host "Enter the number of the user you want to change the password for"

        # Try to parse the user input as an integer
        $parsed = [int]::TryParse($userNumber, [ref]$null)

        # If the entered number is a valid integer and within the range of the number of users, return the number
        # Otherwise, display an error message
        if ($parsed -and [int]$userNumber -ge 1 -and [int]$userNumber -le $usersCount) {
            return $userNumber
        }

        Write-Host "Invalid user number"
    }
}
# This function generates a random password
function Generate-Password() {
    # Define a list of words to use in the password
    $words = 'Frog', 'Hop', 'Leap', 'Pond', 'Log', 'Track', 'Pop', 'Otter', 'Grass', 'Rocket', 'Loop', 'Bop', 'Pull', 'Flight', 'World', 'Music', 'Honey', 'Otter', 'Slap', 'Glare', 'Bad', 'Good', 'Ramp', 'Glide', 'Bear', 'Arm', 'Apple', 'Pear', 'Peach', 'Age', 'Brand', 'Bend', 'Cloud', 'Truck', 'Car', 'Lake', 'Sea'

    # Return a password composed of two random words and a random number between 1000 and 9999
    return "$(Get-Random -InputObject $words)$(Get-Random -InputObject $words)@$(Get-Random -Minimum 1000 -Maximum 9999)"
}

# This function resets the password of the selected user and unlocks their account
function Reset-Password($selectedUser, $password) {
    # Reset the password of the selected user
    $selectedUser | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)

    # Unlock the account of the selected user
    $selectedUser | Unlock-ADAccount
}

# This function asks the user if they want to continue changing passwords
function Ask-Continue() {
    # Prompt the user to enter whether they want to continue
    $continue = Read-Host "Do you want to change another password? (y/n)"

    # If the user entered "y", clear the screen, show the title again, and return true
    if ($continue -eq "y") {
        Clear-Host
        Show-TitleScreen
        return $true
    }

    # Otherwise, return false
    return $false
}

# Show the title screen
Show-TitleScreen

# Import ActiveDirectory module
Import-module ActiveDirectory

# Main loop to reset passwords
while ($true) {
    $searchCriteria = Read-Host "Enter the first name, last name, or username of the person you want to change the password for"
    Add-Content -Path $logFile -Value ("SEARCH: $searchCriteria At: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))
    $users = @(Get-Users $searchCriteria)  # Force $users to be an array
    Display-Users $users
    $userNumber = Get-UserNumber $users.Count
    $selectedUser = $users[$userNumber - 1]
    $password = Generate-Password
    Reset-Password $selectedUser $password
    Add-Content -Path $logFile -Value ("USER: $($selectedUser.Username) Reset At: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))
    $password | Set-Clipboard

    # Change background color
    $host.UI.RawUI.BackgroundColor = "DarkGreen"
    Write-Host "Password reset and account unlocked for $($selectedUser.SamAccountName). The new password has been copied to the clipboard."

    # Change background color back to black
    $host.UI.RawUI.BackgroundColor = "Black"

    if (!(Ask-Continue)) {
        break
    }
}

Add-Content -Path $logFile -Value ("END: " + (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"))