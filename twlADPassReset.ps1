# This script resets Active Directory user passwords. It prompts for search criteria, finds matching users, and allows selection of a user. 
# It generates a random password, resets the selected user's password, unlocks the account, and copies the new password to the clipboard. 
# It repeats until the user chooses to stop.

# Import ActiveDirectory module
Import-module ActiveDirectory

while ($true) {
    # Ask the user to enter the search criteria
    $searchCriteria = Read-Host "Enter the first name, last name, or username of the person you want to change the password for"

    # Search for users in Active Directory based on the search criteria
    $users = Get-ADUser -Filter "GivenName -like '*$searchCriteria*' -or Surname -like '*$searchCriteria*' -or SamAccountName -like '*$searchCriteria*'" -Properties LockedOut, LastLogonDate, SamAccountName, Name, EmailAddress, whenCreated

    # Check if any users are found
    if ($users.Count -eq 0) {
        Write-Host "No users found that match the search criteria"
        continue
    }

    # Display the found users with their information
    Write-Host "Found users:"
    $users | ForEach-Object {
    $lockedOut = if ($_.LockedOut) { "LOCKED" } else { "NOT" }
    $lastLogon = if ($_.LastLogonDate) { $_.LastLogonDate.ToString() } else { "Never logged in" }
    $created = if ($_.whenCreated) { $_.whenCreated.ToString() } else { "N/A" }
    [PSCustomObject]@{
        'Number' = $users.IndexOf($_) + 1
        'SamAccountName' = $_.SamAccountName
        'Name' = $_.Name
        'Email' = $_.EmailAddress
        'Locked?' = $lockedOut
        'Created On' = $created
        'Last Logon' = $lastLogon
    }
} | Format-Table -AutoSize

    # Ask the user to select a user by entering the corresponding number
    $userNumber = Read-Host "Enter the number of the user you want to change the password for"

    # Validate the user input
    if (![int]::TryParse($userNumber, [ref]$null) -or $userNumber -lt 1 -or $userNumber -gt $users.Count) {
        Write-Host "Invalid user number"
        continue
    }

    # Get the selected user
    $selectedUser = $users[$userNumber - 1]

    # Define a list of words
    $words = 'Frog', 'Hop', 'Leap', 'Pond', 'Log', 'Track', 'Pop', 'Otter', 'Grass', 'Rocket', 'Loop', 'Bop', 'Pull', 'Flight', 'World', 'Music', 'Honey', 'Otter', 'Slap', 'Glare', 'Bad', 'Good', 'Ramp', 'Glide', 'Bear', 'Arm', 'Apple', 'Pear', 'Peach', 'Age', 'Brand', 'Bend', 'Cloud', 'Truck', 'Car', 'Lake', 'Sea'

    # Generate a random password
    $password = "$(Get-Random -InputObject $words)$(Get-Random -InputObject $words)@$(Get-Random -Minimum 1000 -Maximum 9999)"

    # Reset the password and unlock the account for the selected user
    $selectedUser | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
    $selectedUser | Unlock-ADAccount

    # Copy the password to the clipboard
    $password | Set-Clipboard

    Write-Host "Password reset and account unlocked for $($selectedUser.SamAccountName). The new password has been copied to the clipboard."

    # Ask the user if they want to continue
    $continue = Read-Host "Do you want to change another password? (y/n)"
    if ($continue -ne "y") {
        Write-Host "The program has ended. Press escape to close the program."
        break
    }
}