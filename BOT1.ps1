[string] $target = "https://rohitmadhav02.atlassian.net"
[string] $username = "rohit.kumar@relevancelab.com"
[string] $password = "relevancelab"


function set-Headers
{
$basicAuth = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Username):$Password"))
$headers = @{
Authorization = $basicAuth
}
return $headers
}

function get-RestData
{
param([Parameter(Mandatory=$True)] $headers,
[Parameter(Mandatory=$True)]$requestURI)
return Invoke-RestMethod -uri $requestURI -Method Get -Headers $headers
}



Function Add-Jira-User
{
param([Parameter(Mandatory=$True)] $emailAddress,
[Parameter(Mandatory=$True)]$displayName)

$headers = set-Headers
$requestURI = "$target/rest/api/2/user"
$Data= @{
"X-ExperimentalApi" = "true"
     username="Ashish"
     password="qwerty@1234"
     emailAddress= "ashish@relevancelab.com"
     displayName= "Ashish pushp"

}


$json = ConvertTo-Json -InputObject $Data
$response=Invoke-RestMethod -uri $requestURI -Method POST -Headers $headers -Body $json -ContentType "application/json"
Write-Host $response.status
}

Function Get-Jira-Users
{

$headers = set-Headers
$requestURI = "https://rohitmadhav02.atlassian.net/rest/api/2/user/?username=admin"
$response=get-RestData -headers $headers -requestURI $requestURI
return $response.values
}



#$users=Get-Jira-Users
#$users

Add-Jira-User -emailAddress "akash.kumar@relevancelab.com" -displayName "akashkumar"

 