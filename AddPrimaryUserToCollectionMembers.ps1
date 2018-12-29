#Script parameters
#The user, which has to be added as a primary to all collection members
$UserSAM = "UserName"
#The name of the collection
$CollectionName = "TestCollection"
#NetBIOS name of the domain
$DomainNetBIOS = "Domain"


#Set the error action preference
$ErrorActionPreference = "Stop"
$error.Clear()

#Import SCCM Modules
If (!(Get-Module ConfigurationManager)) {
    $SCCMPath = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\ConfigMgr10\AdminUI\QueryProcessors\WQL).'Assembly Path'
    $SCCMModule = ($SCCMPath.Substring(0,$SCCMPath.Length-26)) + "ConfigurationManager.psd1"
    Import-Module $SCCMModule -Scope Global
}

#Connect to the SCCM Environment
if (!(Get-PSDrive -PSProvider CMSite)) {
    $SCCMServer = (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\ConfigMgr10\AdminUI\Connection -Name Server).Server
    $SCCMParams = ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\CCMSetup).'LastSuccessfulInstallParams')
    $SCCMCode = ($SCCMParams.Substring($SCCMParams.Length-5,5)).Substring(1,3)
    Update-TypeData -PrependPath (($SCCMPath.Substring(0,$SCCMPath.Length-26)) + 'Microsoft.ConfigurationManagement.PowerShell.Types.ps1xml')
    New-PSDrive -Name $SCCMCode -PSProvider CMSite -Root $SCCMServer -Scope Global                                
}
#Set the PSDrive location
Set-Location ((get-psdrive -PSProvider CMSite).Name + ":")

#Get the User
try {
    $SCCMUserSMSID = (Get-CMUser -Name ($DomainNetBIOS + "\" + $UserSAM)).SMSID
} catch {
    $ErrorMessage = "Unable to get the user from SCCM"
    Write-Host $ErrorMessage
    Throw $ErrorMessage
}

#Get all the devies from the collection
try {
   $Devices = Get-CMCollection -Name $CollectionName | Get-CMCollectionMember
} catch {
    $ErrorMessage = "Unable to get the collections members"
    Write-Host $ErrorMessage
    Throw $ErrorMessage  
}

#Iterate all the devices in the collection
foreach ($DevicePiece in $Devices) {

    #Get the name of the device
    $DeviceName = $DevicePiece.Name

    #Actions to be completed only if device object is found
    if ((Get-CMDevice -Name $DeviceName)) {
        
        try {
            #Create the relationship between a device and a user
            Add-CMUserAffinityToDevice -DeviceName $DeviceName -UserName $SCCMUserSMSID -Force
        
        } catch {
            $ErrorMessage = "Unable to add the user to the device."
            Write-Host $ErrorMessage
            Throw $ErrorMessage

        }
    }
}