##This script add members to a distribution list, delete members from a distribution list and modify the owner of the group
$groupname=$args[0] #group name to be created
$connectionUri=$args[1] #URI of the server
$serverusername=$args[2]#username of the server
$serverpassword=$args[3]#password of the server
$addusers=$args[4]#list of users to be added
$deleteusers=$args[5]#list of users to be deleted
$modify_owner=$args[6]
$task_sys_id=$args[7] #task sysid
$task_number=$args[8] #task number




$location="C:\logFile.txt" #log location-c:\$logFile.txt
$domain="rlpl1.com/"
$exit=1 #if exit is 1 will return run failed else if exit 0 will return run success
$status #check status if bot run successfully or failed
$messagedetails="Modify Distribution List"
#Splitting username 
if($addusers -ne $null)
{
    $addusers = $addusers.Trim()
    $addusers = $addusers.Split(",")
}
#Splitting username 
if($deleteusers -ne $null){
$deleteusers = $deleteusers.Trim()
$deleteusers = $deleteusers.Split(",")
}
#convert password into secure string and return the user and password as a string
function GetCred {
    param(
        [string]$user, 
        [string]$password
        )
    if ($password)
    {
        $passwordSecure = convertto-securestring -string $password -asplaintext -force;
    }
    else
    {
        $passwordSecure = new-object System.Security.SecureString;
    }
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$user",$passwordSecure;
    return $cred;
}

#store the credential in the variable
$credential = GetCred -user $serverusername -password $serverpassword
$logdata="Modify Distribution List Log File:" +"`n" +$(Get-Date)
try
{
	#create a session with the server using server ip and the credential of the server
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri  $connectionUri -Authentication Kerberos -ErrorAction SilentlyContinu -Credential $credential
	$Import= Import-PSSession $Session -ErrorAction SilentlyContinue -AllowClobber
	Import-Module activedirectory
		try{

			#check if group with the same name exist
			$filter = "{Name -eq '$groupname'}"
			$groupexist = Get-DistributionGroup -Filter -$filter | Select-Object Name
			#if not exist then modify the group
			if($groupexist.Name -ne $null)
            {
				#this script has three scenarios 1. addusers 2. deleteusers 3.modify owner
				#this is first scenario add members in distribution list
				if($addusers -ne $null)
                 {	
					$messagedetails="add user to distribution list"
					#get the list of group members
					$groupmember=Get-DistributionGroupMember -Identity "$groupname" | Select -ExpandProperty samaccountname
					foreach ($singleuser in $addusers)
					{
						if($singleuser -ne $null)
                        {
						    try
                            {     
							    # Getting the user from AD
							    $user = Get-ADUser $singleuser | Select-Object samaccountname
						    }catch{
							    $user = $null
							}
							#check the user samaccountname
						    if($user.samaccountname){
							    if ($groupmember -contains $user.samaccountname) {	
									#if the samaccount name contains the same name as of group member then return log message							
								    $logdata=$logdata+"`nUser $user already exist in the group"
                                    $exit=0
							    }
						 	    else {
									 #if the samaccount name doesn't contains the same name as of group member add the user
								    Add-DistributionGroupMember -Identity "$groupname" -Member $user.samaccountname -Confirm:$false
                                    $exit=0
                                    $logdata=$logdata+"`nUser $user Successfully Added in the group"
                        
							    }	
							    
						    }
					    }
					
				    }
				}
				#this is second scenario delete users from the distribution list
				if($deleteusers -ne $null)
                {
					$messagedetails="delete user from distribution list"
					#get the list of group member
                    $groupmember=Get-DistributionGroupMember -Identity "$groupname" | Select -ExpandProperty samaccountname
					foreach ($singleuser in $deleteusers)
					{
						if($singleuser -ne $null)
                        {
						    try{     
							    # Getting the user from AD
							    $user = Get-ADUser $singleuser | Select-Object samaccountname
						    }catch
                            {
							    $user = $null
						    }
						    if($user.samaccountname){	
							    if ($groupmember -contains $user.samaccountname) {
									#if user samaccountname is same in the groupmember then delete the members from the distibution list
								   Remove-DistributionGroupMember -Identity "$groupname" -Member $user.samaccountname -Confirm:$false
								   $logdata=$logdata+"`nUser $user successfully deleted from the Distribution List"
                                    $exit=0
							    }
						 	    else {
									 #if user samaccountname is not same in the groupmember then delete the members from the distibution list
                                   $logdata=$logdata+"`nUser $user doesn't exist in the group"
                                   $exit=0
							    }	
							    
						    }
					    }
                    
				    }
				}
				#this is the last scenario modify the owner of the group
				if($modify_owner -ne $null){
					$messagedetails="Change owner name of the distribution List"
					#check for the group owner name
                    $groupmember=Get-DistributionGroup -Identity $groupname | Select -ExpandProperty Managedby
					if($groupmember -ne $null)
                    {#if group owner is not null i
                        try{    
							    # Getting the user from AD
							    $user = Get-ADUser $modify_owner | Select-Object Name
						 }
                        catch
                        {
							    $user = $null
					    }
                        if($user -ne $null){
							#add the domain name before the username
                            $tempname=$user.name
                            $tempname="$domain$tempname"
                            if($groupmember -ne $tempname)
						    {
									#if username is not same as the older owner name then change the owner name
							        Set-DistributionGroup -Identity $groupname -Managedby $user.name
                                     $logdata=$logdata+ "`nOwner Name Changed Suucessfully"
                                     $exit=0
						    }
                            else{
                               $logdata=$logdata+ "`nUser is already the owner of the group"
                               $exit=0
                            }
                        }
                        else{
                                 $logdata=$logdata+ "`nUser is not present in the AD"
                                 $exit=0
                       
                        }
					  }
                      

                    
				  }   
		    }
            else{
				    #if exist then return message in a log file
				    $logdata=$logdata + "`ngroup doesnot exist in the Distribution List"
				    $exit=1
			    }
      
      }catch
      {
			#error message is captured in a log file
			$exit=1
			$ErrorMessage = $_.Exception.Message
			$logdata=$logdata +"`nsome error occurred inside Exchange Server"+ "`n" + [string]$ErrorMessage
			
	   }
	Remove-PSSession $Session

}catch{	
		#error message is captured in a log file
		$exit=1
		$ErrorMessage = $_.Exception.Message
		$logdata=$logdata +"`nsome error occurred outside Exchange Server"+ "`n" + [string]$ErrorMessage
		
}


function botstatus
{
	if($exit -eq 0)
	{
		#if exist is true return success
		return "success"
	}
	else{
		#if exist is false return failed
		return "failed"
	}
}
$status=botstatus 
Write-Host "status:"$status
$logdata=$logdata + "`n" +[string]$status
$logdata=$logdata + "`n`n`n"
#all the log message is append and written in a log file
[string]$logdata | Out-File $location -Append
exit($exit)

