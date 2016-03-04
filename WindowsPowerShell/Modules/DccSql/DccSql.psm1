#Import-Module “sqlps” -DisableNameChecking

function Rename-AllFilesInFolder ($oldextension, $newextension)
{
	if ($oldextension.Substring(0,1) -eq '.')
	{
		$oldextension = $oldextension.Substring(1)
	}	
	if ($newextension.Substring(0,1) -eq '.')
	{
		$newextension = $newextension.Substring(1)
	}
	
	get-childitem *.$oldextension | rename-item -newname{$_.name -replace "\.$oldextension", ".$newextension"}
}

function Alter-FwiUser ($newusername, $oldusername)
{
	# Edit these for your information!
	$yourname = "Neil Holmes"
	$yourmail = "neil.holmes@derbyshire.gov.uk"
	$yoursig = "Neil Holmes
Database Administration Team
Transformation Services
01629 532452
32452"
	#Force $username to be a string
	If ($newusername.GetType().name -ne "String")
	{$newusername = $newusername.ToString()}
	If ($oldusername.GetType().name -ne "String")
	{$oldusername = $oldusername.ToString()}

	Try
	{
		# Start the SQL libraries
		Invoke-SQLcmd

		# Switch to FW Prod
		cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwprod
		#Drop the user in prod
		Invoke-SQLcmd "IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'$oldusername') DROP SCHEMA [$oldusername]" -Erroraction Stop
		Invoke-SQLcmd "IF  EXISTS (SELECT * FROM sysusers WHERE name = N'$oldusername') DROP USER [$oldusername]" -ErrorAction Stop
		# Switch to UATest
		cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwuatest
		Invoke-SQLcmd "IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'$oldusername') DROP SCHEMA [$oldusername]" -Erroraction Stop
		#Drop the user in UATest
		Invoke-SQLcmd "IF  EXISTS (SELECT * FROM sysusers WHERE name = N'$oldusername') DROP USER [$oldusername]" -ErrorAction Stop
		
		# Switch to the master database
		cd SQLSERVER:\SQL\d-db91\db91\databases\master
		#Alter the login
		Invoke-SQLcmd "ALTER LOGIN [$oldusername] WITH NAME=[$newusername], DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF" -ErrorAction Stop
		
		# Switch to FW Prod
		cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwprod
		#Create the user in prod
		Invoke-SQLcmd "CREATE USER [$newusername] FOR LOGIN [$newusername]" -ErrorAction Stop
		# Switch to UATest
		cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwuatest
		#Create the user in UATest
		Invoke-SQLcmd "CREATE USER [$newusername] FOR LOGIN [$newusername]" -ErrorAction Stop
		
		# Test if the payroll number is in the GAL
		$validpn = Get-ADUser -filter {samaccountname -eq $newusername}
		If($validpn)
		{
			$givenname = (Get-ADUser $newusername).GivenName
			Send-MailMessage -to (Get-ADUser $newusername -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Frameworki Account Created" -body "Hi $givenname,
				`n
I've changed your username for Frameworki (usually as part of a payroll change), your new login details are below. Your password will be the same as it was before, simply use the new username instead of your old one. If you need your password resetting then let me know.
Old user name: $oldusername
New user name (use this one from now on!): $newusername
				`n

				$yoursig"
			Write-Host "Account $oldusername altered to $newusername and details emailed to $givenname."
		}
		#If the payroll number is not in the GAL
		Else
		{
			Write-Host "The user's payroll doesn't have a matching email address."
			$sendto = Read-Host -prompt "Enter the payroll number of the user to send the password to"
			$userfor = Read-Host -prompt "Enter the name of the user the password is for"
			$givenname = (Get-ADUser $sendto).GivenName
			
			Send-MailMessage -to (Get-ADUser $sendto -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Frameworki Account Created" -body "Hi $givenname,
				`n
The Frameworki password for $userfor is below. After logging in can you please advise the user to change their password to a new complex one by going to Privacy Settings -> Change Your Password within Frameworki.`n
User name: $username
Password: $passwd
				`n

				$yoursig"
			Write-Host "Account $oldusername altered to $newusername and details emailed to $sendto."
		}
		
	}
	Catch
	{
		"Problems with user creation."
		$err = $_.exception
		   write-output $err.Message
	   while( $err.InnerException ) {
			   $err = $err.InnerException
			   write-output $err.Message
			  }
	}
	Finally
	{"Script complete"}
}

Function Get-DnetPhoneNumber {
       <#
              .SYNOPSIS
                     Gets the phone number of the passed name

              .DESCRIPTION
                     Gets the phone number of the passed name

              .PARAMETER  Name
                     Name to find phone number for

              .EXAMPLE
                     PS C:\> Get-DnetPhoneNumber -Name Test
                     
                     Name                           Ext        AltExt     Division
                     ----                           ---        ------     --------
                     Test 1                         12345                 Demo, Test
                     Test 1                         54321      11111      Demo, Test

       #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                   HelpMessage="Name of person",
                   ValueFromPipeline=$true,
                   ValueFromRemainingArguments=$true
        )]
        $Name
    )
    Begin {
        $link = 'http://dnet/directory/people_search.asp?People='
        Function New-DnetUser {
            # Creates a new blank object to put information into
            $Object = New-Object PSObject -Property ([ordered]@{
                Name     = ""
                Ext      = ""
                AltExt   = ""
                Division = ""
            })
            $Object.PSObject.typenames.insert(0,'RITools.DnetPhoneNumber')
            $Object
        }
    }
    Process {
        Write-Host $Remaining
        $Lookup = $Name -split '\s+' -join "+"
        Try {
            $ProgressPreference = 'SilentlyContinue'
            $html = Invoke-WebRequest -Uri ($link + $Lookup) -UseDefaultCredentials -ErrorAction Stop
            $ProgressPreference = 'Continue'
        }
        Catch {
            Write-Error $Error[0].Exception.Message -ErrorAction Stop
        }

        $Elements = $html.AllElements | Where class -Match "Column(1|2)|AlternativeNumber|DivisionInformation"

        Write-Verbose "$($Elements.count) elements found"
        $Object = New-DnetUser
        Foreach ($Element in $Elements) {
            Write-Verbose $Element.innerText
            Switch ($Element.class) {
                Column1 {
                    # Checks if there is already information in the object
                    If ($Object.Name -eq "") {
                        $Object.Name = $Element.innerText
                    }
                    Else {
                        # Write out the information and creates a new object
                        $Object
                        $Object = New-DnetUser
                        $Object.Name = $Element.innerText
                    }
                }
                Column2 {$Object.Ext = ($Element.innerText.split(":"))[1].Trim()}
                AlternativeNumber {$Object.AltExt = ($Element.innerText.split(":"))[1].Trim()}
                DivisionInformation {$Object.Division = $Element.innerText}
            }
        }
        # Checks if there is information to be wrote
        If ($Object.Name -ne "") {$Object}
    }
} 

function Get-Payroll ($firstname, $lastname)
{
	If ($firstname.GetType().name -ne "String")
	{$firstname = $firstname.ToString()}
	If ($lastname.GetType().name -ne "String")
	{$lastname = $lastname.ToString()}
	$firstname = $firstname + "*"
	$lastname = $lastname + "*"
	$userobj = Get-ADUser -filter {surname -like $lastname -and givenname -like $firstname}
	$userobj.givenname + " " + $userobj.surname
	$userobj.samaccountname
}

function New-FwiUser ($username) 
{
	# Edit these for your information!
	$yourname = "Neil Holmes"
	$yourmail = "neil.holmes@derbyshire.gov.uk"
	$yoursig = "Neil Holmes
Database Administration Team
Transformation Services
01629 532452
32452"
	#Force $username to be a string
	If ($username.GetType().name -ne "String")
	{$username = $username.ToString()}

	Try
	{
		# Start the SQL libraries
		Invoke-SQLcmd
		
		# See if the user has a valid worker role
		cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwprod
		$sqltext = "SELECT COUNT(*) FROM dbo.workers w, [ss_fwprod].dbo.worker_roles r WHERE w.system_user_id LIKE '$username%' AND   w.id = r.worker_id AND START_DATE <= GETDATE() AND END_DATE IS NULL"
		$workerrole = Invoke-Sqlcmd $sqltext

		
		# If theuser has a valid worker role
		If ($workerrole.Column1 -gt 0)
		{	
			# Switch to the master database
			cd SQLSERVER:\SQL\d-db91\db91\databases\master
			# Generate a new password
			$passwd = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 8
			#Create the login
			Invoke-SQLcmd "CREATE LOGIN [$username] WITH PASSWORD=N'$passwd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF" -ErrorAction Stop
			# Switch to FW Prod
			cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwprod
			#Create the user in prod
			Invoke-SQLcmd "CREATE USER [$username] FOR LOGIN [$username]" -ErrorAction Stop
			# Switch to UATest
			cd SQLSERVER:\SQL\d-db91\db91\databases\ss_fwuatest
			#Create the user in UATest
			Invoke-SQLcmd "CREATE USER [$username] FOR LOGIN [$username]" -ErrorAction Stop
			
			# Test if the payroll number is in the GAL
			$validpn = Get-ADUser -filter {samaccountname -eq $username}
			If($validpn)
			{
				$givenname = (Get-ADUser $username).GivenName
				Send-MailMessage -to (Get-ADUser $username -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Frameworki Account Created" -body "Hi $givenname,`n
I've created your new account for Frameworki, your login details are below. After logging in can you please change your password to a new complex one by going to Privacy Settings -> Change Your Password within Frameworki.`n
User name: $username
Password: $passwd
`n

$yoursig"
				Write-Host "Account $username created and password $passwd emailed to $givenname."
			}
			#If the payroll number is not in the GAL
			Else
			{
				Write-Host "The user's payroll doesn't have a matching email address."
				$sendto = Read-Host -prompt "Enter the payroll number of the user to send the password to"
				$userfor = Read-Host -prompt "Enter the name of the user the password is for"
				$givenname = (Get-ADUser $sendto).GivenName
				
				Send-MailMessage -to (Get-ADUser $sendto -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Frameworki Account Created" -body "Hi $givenname,
					`n
The Frameworki password for $userfor is below. After logging in can you please advise the user to change their password to a new complex one by going to Privacy Settings -> Change Your Password within Frameworki.`n
User name: $username
Password: $passwd
					`n

					$yoursig"
				Write-Host "Account $username created and password $passwd emailed to $sendto."
			}
			
		}
		# If the user does not have an active worker role
		Else
		{"No valid worker role for $username"}
			
	}
	Catch
	{
		"Problems with user creation."
		$err = $_.exception
		   write-output $err.Message
	   while( $err.InnerException ) {
			   $err = $err.InnerException
			   write-output $err.Message
			  }
	}
	Finally
	{"Script complete"}
}

function New-SWRandomPassword {
    <#
    .Synopsis
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .DESCRIPTION
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .EXAMPLE
       New-SWRandomPassword
       C&3SX6Kn

       Will generate one password with a length between 8  and 12 chars.
    .EXAMPLE
       New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 12 -Count 4
       7d&5cnaB
       !Bh776T"Fw
       9"C"RxKcY
       %mtM7#9LQ9h

       Will generate four passwords, each with a length of between 8 and 12 chars.
    .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString
    .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4 -FirstChar abcdefghijkmnpqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString that will start with a letter from 
       the string specified with the parameter FirstChar
    .OUTPUTS
       [String]
    .NOTES
       Written by Simon Wåhlin, blog.simonw.se
       I take no responsibility for any issues caused by this script.
    .FUNCTIONALITY
       Generates random passwords
    .LINK
       http://blog.simonw.se/powershell-generating-random-password-for-active-directory/
   
    #>
    [CmdletBinding(DefaultParameterSetName='FixedLength',ConfirmImpact='None')]
    [OutputType([String])]
    Param
    (
        # Specifies minimum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({$_ -gt 0})]
        [Alias('Min')] 
        [int]$MinPasswordLength = 8,
        
        # Specifies maximum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({
                if($_ -ge $MinPasswordLength){$true}
                else{Throw 'Max value cannot be lesser than min value.'}})]
        [Alias('Max')]
        [int]$MaxPasswordLength = 12,

        # Specifies a fixed password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='FixedLength')]
        [ValidateRange(1,2147483647)]
        [int]$PasswordLength = 8,
        
        # Specifies an array of strings containing charactergroups from which the password will be generated.
        # At least one char from each group (string) will be used.
        [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '!"#%&'),

        # Specifies a string containing a character group from which the first character in the password will be generated.
        # Useful for systems which requires first char in password to be alphabetic.
        [String] $FirstChar,
        
        # Specifies number of passwords to generate.
        [ValidateRange(1,2147483647)]
        [int]$Count = 1
    )
    Begin {
        Function Get-Seed{
            # Generate a seed for randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
        }
    }
    Process {
        For($iteration = 1;$iteration -le $Count; $iteration++){
            $Password = @{}
            # Create char arrays containing groups of possible chars
            [char[][]]$CharGroups = $InputStrings

            # Create char array containing all chars
            $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

            # Set password length
            if($PSCmdlet.ParameterSetName -eq 'RandomLength')
            {
                if($MinPasswordLength -eq $MaxPasswordLength) {
                    # If password length is set, use set length
                    $PasswordLength = $MinPasswordLength
                }
                else {
                    # Otherwise randomize password length
                    $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                }
            }

            # If FirstChar is defined, randomize first char in password from that string.
            if($PSBoundParameters.ContainsKey('FirstChar')){
                $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
            }
            # Randomize one char from each group
            Foreach($Group in $CharGroups) {
                if($Password.Count -lt $PasswordLength) {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index)){
                        $Index = Get-Seed                        
                    }
                    $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                }
            }

            # Fill out with chars from $AllChars
            for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
                $Index = Get-Seed
                While ($Password.ContainsKey($Index)){
                    $Index = Get-Seed                        
                }
                $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
            }
            Write-Output -InputObject $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
        }
    }
}

function New-TribalUser ($username) 
{
	$yourname = "Neil Holmes"
	$yourmail = "neil.holmes@derbyshire.gov.uk"
	$yoursig = "Neil Holmes
Database Administration Team
Transformation Services
01629 532452
32452"
	#Force $username to be a string
	If ($username.GetType().name -ne "String")
	{$username = $username.ToString()}
	
	Try
	{
		Invoke-SQLcmd
		cd SQLSERVER:\SQL\d-db92\db92\databases\master
		$passwd = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 8
		Invoke-SQLcmd "CREATE LOGIN [$username] WITH PASSWORD=N'$passwd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF" -ErrorAction Stop
		cd SQLSERVER:\SQL\d-db92\db92\databases\EDUC_IDR_IDEAR
		Invoke-SQLcmd "CREATE USER [$username] FOR LOGIN [$username]" -ErrorAction Stop
		Invoke-SQLcmd "EXEC sp_addrolemember N'FOUNDATION', '$username'" -ErrorAction Stop
		Invoke-SQLcmd "sp_addrolemember N'IDEAR', '$username'" -ErrorAction Stop
		$givenname = (Get-ADUser $username).GivenName
		Send-MailMessage -to (Get-ADUser $username -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "TRIBAL Account Created" -body "Hi $givenname,
			`n
I've created a new Tribal account for you, your login details are below. 
Please note that you will not be able to log in to the Tribal system until CAYA DMT notify you that your account has been set up.
`n
User name: $username
Password: $passwd
`n
Note that your login won't work until you are contacted by CAYA DMT.`n

$yoursig"
		Write-Host "Account $username created and password $passwd emailed to user."
	}
	Catch
	{
		"Problems with user creation."
		$err = $_.exception
		   write-output $err.Message
	   while( $err.InnerException ) {
			   $err = $err.InnerException
			   write-output $err.Message
			  }
	}
	Finally
	{"Script complete"}
}

function Reset-FwiUser ($username) 
{
	# Edit these for your information!
	$yourname = "Neil Holmes"
	$yourmail = "neil.holmes@derbyshire.gov.uk"
	$yoursig = "Neil Holmes
Database Administration Team
Transformation Services
01629 532452
32452"
	#Force $username to be a string
	If ($username.GetType().name -ne "String")
	{$username = $username.ToString()}

	Try
	{
		# Start the SQL libraries
		Invoke-SQLcmd
		
		# See if the user has a valid worker role
		cd SQLSERVER:\SQL\d-db91\db91\databases\master
		$workerrole = Invoke-Sqlcmd "SELECT COUNT(*) FROM [ss_fwprod].dbo.workers w, [ss_fwprod].dbo.worker_roles r WHERE w.system_user_id LIKE '$username%' AND   w.id = r.worker_id AND START_DATE <= GETDATE() AND END_DATE IS NULL"
		
		# If theuser has a valid worker role
		If ($workerrole.Column1 -gt 0)
		{	
			# Switch to the master database
			cd SQLSERVER:\SQL\d-db91\db91\databases\master
			# Generate a new password
			$passwd = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 8
			#Create the login
			Invoke-SQLcmd "ALTER LOGIN [$username] WITH PASSWORD=N'$passwd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF" -ErrorAction stop
			
			# Test if the payroll number is in the GAL
			$validpn = Get-ADUser -filter {samaccountname -eq $username}
			If($validpn)
			{
				$givenname = (Get-ADUser $username).GivenName
				Send-MailMessage -to (Get-ADUser $username -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Frameworki Password Reset" -body "Hi $givenname,
`n
I've reset your password for Frameworki, your new login details are below. After logging in can you please change your password to a new complex one by going to Privacy Settings -> Change Your Password within Frameworki.`n
User name: $username
Password: $passwd
`n
$yoursig"
				Write-Host "Password for $username changed to $passwd and emailed to $givenname."
			}
			#If the payroll number is not in the GAL
			Else
			{
				Write-Host "The user's payroll doesn't have a matching email address."
				$sendto = Read-Host -prompt "Enter the payroll number of the user to send the password to"
				$userfor = Read-Host -prompt "Enter the name of the user the password is for"
				$givenname = (Get-ADUser $sendto).GivenName
				
				Send-MailMessage -to (Get-ADUser $sendto -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Frameworki Password Reset" -body "
Hi $givenname,
`n
The Frameworki password for $userfor is below. After logging in can you please advise the user to change their password to a new complex one by going to Privacy Settings -> Change Your Password within Frameworki.`n
User name: $username
Password: $passwd
`n
$yoursig"
				Write-Host "Password for $username changed to $passwd and emailed to $sendto."
			}
			
		}
		# If the user does not have an active worker role
		Else
		{"No valid worker role for $username"}
			
	}
	Catch
	{
		"Problems with user creation."
		$err = $_.exception
		   write-output $err.Message
	   while( $err.InnerException ) {
			   $err = $err.InnerException
			   write-output $err.Message
			  }
	}
	Finally
	{"Script complete"}
}

function Reset-TribalUser ($username) 
{
# Edit these for your information!
	$yourname = "Neil Holmes"
	$yourmail = "neil.holmes@derbyshire.gov.uk"
	$yoursig = "Neil Holmes
Database Administration Team
Transformation Services
01629 532452
32452"
	#Force $username to be a string
	If ($username.GetType().name -ne "String")
	{$username = $username.ToString()}

	Try
	{
		# Start the SQL libraries
		Invoke-SQLcmd
		

		# Switch to the master database
		cd SQLSERVER:\SQL\d-db92\db92\databases\master
		# Generate a new password
		$passwd = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 8
		#Create the login
		Invoke-SQLcmd "ALTER LOGIN [$username] WITH PASSWORD=N'$passwd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF" -ErrorAction STOP
		
		# Test if the payroll number is in the GAL
		$validpn = Get-ADUser -filter {samaccountname -eq $username}
		If($validpn)
		{
			$givenname = (Get-ADUser $username).GivenName
			Send-MailMessage -to (Get-ADUser $username -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Tribal Password Reset" -body "Hi $givenname,
`n
I've reset your password for Tribal, the details of your account are below:`n
User name: $username
Password: $passwd
`n

$yoursig"
			Write-Host "Password for $username changed to $passwd and emailed to $givenname."
		}
		#If the payroll number is not in the GAL
		Else
		{
			Write-Host "The user's payroll doesn't have a matching email address."
			$sendto = Read-Host -prompt "Enter the payroll number of the user to send the password to"
			$userfor = Read-Host -prompt "Enter the name of the user the password is for"
			$givenname = (Get-ADUser $sendto).GivenName
			
			Send-MailMessage -to (Get-ADUser $sendto -properties mail).mail -bcc $yourmail -from "$yourname <$yourmail>" -smtpserver internalsmtp.derbyshire.local -subject "Tribal Password Reset" -body "Hi $givenname,
`n
I've reset the Tribal password for $userfor, the details of their new login are below:`n
User name: $username
Password: $passwd
`n

$yoursig"
			Write-Host "Password for $username changed to $passwd and emailed to $sendto."
		}

			
	}
	Catch
	{
		"Problems with user creation."
		$err = $_.exception
		   write-output $err.Message
	   while( $err.InnerException ) {
			   $err = $err.InnerException
			   write-output $err.Message
			  }
	}
	Finally
	{"Script complete"}
}

# SIG # Begin signature block
# MIIVtQYJKoZIhvcNAQcCoIIVpjCCFaICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDGVXNK72HE0AlxZAAO76Ofgd
# cV2gghDRMIIElDCCA3ygAwIBAgIRAJ/qyBGw8WJHpfwg2AUjrOYwDQYJKoZIhvcN
# AQEFBQAwgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2Fs
# dCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8G
# A1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNF
# UkZpcnN0LU9iamVjdDAeFw0xNTA1MDUwMDAwMDBaFw0xNTEyMzEyMzU5NTlaMH4x
# CzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNV
# BAcTB1NhbGZvcmQxGjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSQwIgYDVQQD
# ExtDT01PRE8gVGltZSBTdGFtcGluZyBTaWduZXIwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQC8NaA2cCKBEcOyg7nTKMY2zSVrqXuyHPabUZzvNfTtCI5e
# OAj4dzwKQuDzcNyj18r1TAvP/yKcCn5o1gmiKoR7pp20qcEz4u8fF0jKOs1G5sWq
# d73jd5r6R1NAKFlDk/GkgervgLVPpwjOum68ynYMl2RZhiS7PYKQqFWxktOgpwWs
# n1MlCBBHmc2Y3mjltFB4o68BzFlDWOR2bn6sx+KeH0+wRy3IDKNJJ4B1jLsGkWUP
# kJv0utGByFxq7BTpJQm/Ixb0lUZAQCG7g5b9hh96yA0QjqL4GQdYf5+9NwJg8qTp
# nUQ/MAXkp3CZUZroF/FVyrJhiWVGp2ryWEZ+qqAHAgMBAAGjgfQwgfEwHwYDVR0j
# BBgwFoAU2u1kdBScFDyr3ZmpvVsoTYs8ydgwHQYDVR0OBBYEFC4tsApEStOHwAIH
# zpd9UGIg/Q+DMA4GA1UdDwEB/wQEAwIGwDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB
# /wQMMAoGCCsGAQUFBwMIMEIGA1UdHwQ7MDkwN6A1oDOGMWh0dHA6Ly9jcmwudXNl
# cnRydXN0LmNvbS9VVE4tVVNFUkZpcnN0LU9iamVjdC5jcmwwNQYIKwYBBQUHAQEE
# KTAnMCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqG
# SIb3DQEBBQUAA4IBAQANu61gERu18A3M5kg6ej4OM9wcuerWIP6jTdDMdk7oGNh5
# 39NPmkJkI4opcoo6bGamPDoXqHBFZcZzw9DOiVT7rGkPWLAZy4affrl+61GSv5vd
# 69Fl8CV7iHzevaXItRRRvMCBMIqFOHvmef5nVZOH/k/ojQ7t83KStcKJgG3RWeMd
# DeqxOO4DnQAZpashm3nDzMI+aH69yU1pTbRkUfuyKHTiU4nOnfqt4tvOq3t+BkR0
# /QqjybenMM1J0pJk8SKmuChFdHnpp847M/mDUJR9aMAdScdgeHo8ZCbVvvoKbeQe
# 4QlTj6nFI6zHnWFCIfAsFnFJOxCvLG8a5jHxFP1sMIIGBDCCBGygAwIBAgIKFmNe
# qQABAAAADjANBgkqhkiG9w0BAQsFADAdMRswGQYDVQQDExJEZXJieXNoaXJlLVJv
# b3QtQ0EwHhcNMTUxMDA2MTQzMTA2WhcNMjUxMDA2MTQ0MTA2WjBWMRUwEwYKCZIm
# iZPyLGQBGRYFbG9jYWwxGjAYBgoJkiaJk/IsZAEZFgpkZXJieXNoaXJlMSEwHwYD
# VQQDExhEZXJieXNoaXJlLUVudGVycHJpc2UtQ0EwggGiMA0GCSqGSIb3DQEBAQUA
# A4IBjwAwggGKAoIBgQClMLZ2vPec7dIRA196H+RY4SylS8OHkuZx4B0QZR36ozzZ
# pUxD9/gWqlkaQiCbhCbon6xx2C3cbpXonTRcAp+8nzqKPTrWPz7RlawlEw9wEYz0
# EGDnMEXH1pS+FcSw6QCHoouDSfwhROmS72n9zE9gjVlZietDUav930UaeUqzNX74
# +uutNNlMwPMPYXpJ/vQq7ftGOV2OxlbgGH8G5vSxGLDbfUlv+3WhecAuB1gylfLF
# EcJxYlb3g9m8KEIg/PVR6kWlCqdi7H4a/65Zh4Z7StGnzJ0tSb61Hb5ycIHMvaIZ
# E35v8AxfiPLEYDqLRCbKLp4/hmtOO+TLklippvF0qHAf+EQImEnx3/DHsBIHSYp1
# 8rCmCXj0AHsVbBpC/DqCIJsIwRUnTcyZvrBuI/r/wTxZiYswgH6jfcHtdhwnBqB6
# FdKXA/6RXScAWzFNvbW72ITvRbDDE74cIdQ8pRo/MtNue0twsfbx2p8r0aQqfxxV
# hqa1GYcmsw8l0v36mhkCAwEAAaOCAgswggIHMBIGCSsGAQQBgjcVAQQFAgMEAAQw
# IwYJKwYBBAGCNxUCBBYEFNxpf0Kp58UfOtH0XmsQhNZynnEMMB0GA1UdDgQWBBQO
# CSorOJxhVheiUjpzCAje5UhmCDA5BgkrBgEEAYI3FAIELB4qAEQAQwBDAC0ASQBz
# AHMAdQBpAG4AZwBDAEEAVABlAG0AcABsAGEAdABlMAsGA1UdDwQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFCS47yaw8T8KOMdWpBJOUww5mTHyMIGE
# BgNVHR8EfTB7MHmgd6B1hjhodHRwOi8vY2EuZGVyYnlzaGlyZS5sb2NhbC9wa2kv
# RGVyYnlzaGlyZS1Sb290LUNBKDEpLmNybIY5aHR0cDovL2NhLmRlcmJ5c2hpcmUu
# Z292LnVrL3BraS9EZXJieXNoaXJlLVJvb3QtQ0EoMSkuY3JsMIGrBggrBgEFBQcB
# AQSBnjCBmzBLBggrBgEFBQcwAoY/aHR0cDovL2NhLmRlcmJ5c2hpcmUubG9jYWwv
# cGtpL1YtQ0EwMV9EZXJieXNoaXJlLVJvb3QtQ0EoMSkuY3J0MEwGCCsGAQUFBzAC
# hkBodHRwOi8vY2EuZGVyYnlzaGlyZS5nb3YudWsvcGtpL1YtQ0EwMV9EZXJieXNo
# aXJlLVJvb3QtQ0EoMSkuY3J0MA0GCSqGSIb3DQEBCwUAA4IBgQBoD4ULerptOVu8
# cp3X+mNxOmjG0DAy9FKxrNHKvwC2opFupXIz71fp/OHwIIg98k6JoXLWDb2Z6cSm
# ZxpVkVGqUwRfyGpHVBqOn9+Uscc18lGzomciOR19ZyiYNdq6Y2fyb/i3n8tOsc/l
# NfdfDBp697NfeIor1IFzlQT/ajEDa6CuuivOG+MvFQEofFpzlMNhDZkyIi1BekJp
# J3gjO7wfDwXrz/vUX9+bIMW6krrAOIwW/vGfVRzNIn9++HTmouJ0BXNspf2OauIf
# 8IvSUJjPCN7XCoYxHQlrlWxJgTQOTWDbyNIs/a1w5FPykqLCt06Oh4yuEqslL4eE
# 9lO6Rs81Wo/6r2QxrXc++nOFaLEjwfaqV9bCGVOddatlZoVMXQ5ETMoYpkfRm8Iz
# cNyMkwbF0CSd0IGYTTPpc70RkMd1ujmfjBj7gkYWf18aIAysMxWGZD7UwDGtARMW
# cCXHsygsHO+Gj4OtfT83Rn1Gfr1b5LlEW6fmSrmhXwfq2vtzOXEwggYtMIIElaAD
# AgECAgoUgkwuAAQAAZi1MA0GCSqGSIb3DQEBCwUAMFYxFTATBgoJkiaJk/IsZAEZ
# FgVsb2NhbDEaMBgGCgmSJomT8ixkARkWCmRlcmJ5c2hpcmUxITAfBgNVBAMTGERl
# cmJ5c2hpcmUtRW50ZXJwcmlzZS1DQTAeFw0xNTExMTkxMDE3NTdaFw0xODExMTgx
# MDE3NTdaMEExETAPBgNVBAMTCEE5NDA1NzU2MSwwKgYJKoZIhvcNAQkBFh1OZWls
# LkhvbG1lc0BkZXJieXNoaXJlLmdvdi51azCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBAKxsu6qUMklph2XSkSE/e2ZNDuRI6aXNiXqrK8kKQqu1MhQEBrwE
# KVj+CIuveczv5WAj1F4GKsQDPlVCQC89IADw6d3Dvha21oVjCjCge9A9UwD9E8jH
# ao0KTPwPP5FE1M2iSP0a2Yn5Z/wG+HHbJxWJ+pxDOJoUC/7z2EDv64rvvod3xni6
# jrMn8b9uMLJsdrjJqoBvVtoGCuAiys8H4EPDg7JidNcaSvtFJOkyT6G0ObYIwGCg
# 1kfBZ76uizDSOp17i3gdwibClTCUzXuJ2CDfpHkpPQShFVpRlzjkooyh9JmZQTb1
# I+PMPeehe+0sZl4Qp+Xhhc8hxhRN4EPoujkCAwEAAaOCApAwggKMMD0GCSsGAQQB
# gjcVBwQwMC4GJisGAQQBgjcVCIOwwACD1JI8xZklh5PbPoOn9SyBbYWu9l+Fq8cq
# AgFkAgEHMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAbBgkr
# BgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBQZp/+HFg59XOCatICo
# c26PsIuaiTAfBgNVHSMEGDAWgBQOCSorOJxhVheiUjpzCAje5UhmCDCBlQYDVR0f
# BIGNMIGKMIGHoIGEoIGBhj5odHRwOi8vY2EuZGVyYnlzaGlyZS5sb2NhbC9wa2kv
# RGVyYnlzaGlyZS1FbnRlcnByaXNlLUNBKDQpLmNybIY/aHR0cDovL2NhLmRlcmJ5
# c2hpcmUuZ292LnVrL3BraS9EZXJieXNoaXJlLUVudGVycHJpc2UtQ0EoNCkuY3Js
# MIHbBggrBgEFBQcBAQSBzjCByzBjBggrBgEFBQcwAoZXaHR0cDovL2NhLmRlcmJ5
# c2hpcmUubG9jYWwvcGtpL0QtQ0EtMDEuZGVyYnlzaGlyZS5sb2NhbF9EZXJieXNo
# aXJlLUVudGVycHJpc2UtQ0EoNCkuY3J0MGQGCCsGAQUFBzAChlhodHRwOi8vY2Eu
# ZGVyYnlzaGlyZS5nb3YudWsvcGtpL0QtQ0EtMDEuZGVyYnlzaGlyZS5sb2NhbF9E
# ZXJieXNoaXJlLUVudGVycHJpc2UtQ0EoNCkuY3J0MFMGA1UdEQRMMEqgKQYKKwYB
# BAGCNxQCA6AbDBlBOTQwNTc1NkBkZXJieXNoaXJlLmxvY2FsgR1OZWlsLkhvbG1l
# c0BkZXJieXNoaXJlLmdvdi51azANBgkqhkiG9w0BAQsFAAOCAYEARXEz0F5/AaV0
# K1zKpnUPFF2h6WEmM/C+A75/JNUP/aEbK9fEUa7blUDsRhYWbUMds6gGudtyLjAK
# jMIn38BOOcrebWZ+tD//ACcYYkui9H5/Sk92W+LfFJ+ZrglRMtEJQyGb+Tn3Ittd
# 5yAjMIHapT1PIcPIjtm7yRdj9xWK+tTjsxT2lrFFxXwBKz5qB4By/Pp+WEQpHV7X
# /2rIlsiqKoqUzgNGE1wZA9+LvGwHvjN6xgtCMQauasMqhNRaj5XP3tz7B2vYCctA
# yHMW6fLAi7/A4BK7RAn3zvyA5yYDA1Opw+bKCll19iMwQd+CLPRR4wpKEMMuoQqw
# K45QT5/5HlQPEQgOwvYjMPSjdofAuSyjzf5M5oOVXlQ1r/KA+JONnSod96b3GOCO
# 3FtTvO4cSedEPEtLaIrfhNyGK5Tp1bHK/dkQe1P+/zMWY+KKY7POV/VKKevp6P/Q
# PwCDiP5Zx7xmMv6xtVyLKB0KB66h6J5nAmCcAxf4FwH0fOHc5iLWMYIETjCCBEoC
# AQEwZDBWMRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxGjAYBgoJkiaJk/IsZAEZFgpk
# ZXJieXNoaXJlMSEwHwYDVQQDExhEZXJieXNoaXJlLUVudGVycHJpc2UtQ0ECChSC
# TC4ABAABmLUwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFA+VVroyJoQRztOwnyn8hdWaP1E7MA0G
# CSqGSIb3DQEBAQUABIIBAIjnpLICChu+/bF3Y18EGiIKlyVUui0Qf/ZRrHMYyefN
# 5LUA7nYwP2LCEYxa5QIkKiPnPlSdslhkFBpC9BLd+XKmb+BnNB61pYXplk64epxV
# tEuJhb3dP6lQ7HBfoit2iNQweg9yQVw1FrNtAw7kIiKQ5H/IaV/mzuGNdr49yhpF
# x9+Udk/TSTRR7aqzsgwdIuOD/hWuLEGduSEFCcKlWL3f2NQcSgfXw6JGK80K8sS3
# 3wZNPtIPFGi/lOhUc14cbXaMZClBPhMBI743lcYpj5b44IvP0okLWyqS3i5X/qau
# 4OSZQAyzVlFiSHurEef0XDBZiNnKCQ8TSPycOjPRJOahggJFMIICQQYJKoZIhvcN
# AQkGMYICMjCCAi4CAQAwgaswgZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEX
# MBUGA1UEBxMOU2FsdCBMYWtlIENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1Qg
# TmV0d29yazEhMB8GA1UECxMYaHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYD
# VQQDExRVVE4tVVNFUkZpcnN0LU9iamVjdAIRAJ/qyBGw8WJHpfwg2AUjrOYwCQYF
# Kw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkF
# MQ8XDTE1MTEyMDE2MTg0NVowIwYJKoZIhvcNAQkEMRYEFJECFxa5Qq+76ruoWyyx
# rB0Q7XZlMA0GCSqGSIb3DQEBAQUABIIBAFDtTMpSDR6Se0/ZLMvxPbIWKKdtUS5o
# /57rduDaSQmLedUekzCXivnBV4ImyhL+jL3gelhJKnS3vGj3RSnhqlhhyq9cCS6C
# wk4vnfE1xgrdy81ZagpcSpYG125Lm8eqsjoFQF8uFrCFu7cKohBO2coiYkC7CNn1
# wb380Fh4vAnIfR3XbmlKjddpP62Y93C5BwnxW/luOrrKkkgaM0GLUyVdJLHXcGn4
# GaBE2a6UhPwqVXzkxfVInVGzn6N+6NktEmW2Gc8ju5om/DINH4P7QtkmyLgbXYlK
# zpSkR8jnN7arBgrfOzVn7DhYlP5VBhcfeOjJWrVm7o5m3cYY36/TPUc=
# SIG # End signature block
