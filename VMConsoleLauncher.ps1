Param(
    [Parameter(Mandatory=$false)][string]$vCenter,
    [Parameter(Mandatory=$false)][string]$vmname
)

function Open-MyVMConsoleWindow {
    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]$vm
    )
    process {
        $vi=$vm.Uid.Substring($vm.Uid.IndexOf('@')+1).Split(":")[0]
        $ServiceInstance = Get-View -Id ServiceInstance -Server $vi
        $SessionManager  = Get-View -Id $ServiceInstance.Content.SessionManager -Server $vi
        $vmrcURI = "vmrc://clone:" + ($SessionManager.AcquireCloneTicket()) + "@" + $vi + "/?moid=" + $vm.ExtensionData.MoRef.Value
        Start-Process -FilePath $vmrcURI    
    }
}

$certaction = get-PowerCLIConfiguration -scope User
if($certaction.InvalidCertificateAction -ne "Ignore")
{
    write-host "set certificate action to Ignore:"
    Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
}

$vCenterOptions = @{
    "YSE" = "yse-vcenter01.yel.yazaki.local"
    "MTY" = "mont01vcs001.yazaki.local"
    "CANTON" = "cant01vcs001.yazaki.local"
    "YELKO" = "yelko-vcenter01.yel.yazaki.local"
}

$sortedOptions = $vCenterOptions.Keys | Sort-Object

Write-Host "Select a vCenter:"
$i = 1
foreach ($option in $sortedOptions) {
    Write-Host "$i. $option"
    $i++
}

$selectedOption = Read-Host "Enter the number corresponding to your choice"
if ($selectedOption -as [int] -gt $sortedOptions.Count -or $selectedOption -as [int] -lt 1) {
    Write-Host "Invalid selection. Please enter a number between 1 and $($sortedOptions.Count)."
    exit
}

$selectedKey = $sortedOptions[$selectedOption - 1]
$selectedVcenter = $vCenterOptions[$selectedKey]

Connect-VIServer -Server $selectedVcenter -Protocol https -ErrorAction Stop

if(!$vmname){
$vmname = Read-Host 'Enter the VM name: '
$vmfound=Get-VM $vmname
}else{
$vmfound=Get-VM $vmname
}

if($vmfound.count -ge 1)
{   
    $vmdisplay=$vmfound|Foreach-Object{[PSCustomObject] @{ Index = $index; Object = $_ }; $index++}
    $vmdisplay|select-object -property index,@{Label="Guest";Expression={$_.object.guest}},@{Label="PowerState";Expression={$_.object.PowerState}},@{Label="VC";Expression={$_.object.Uid.Substring($_.object.Uid.IndexOf('@')+1).Split(":")[0]}}|Format-Table -autosize

    $vmindex_select=-1
    while(($vmindex_select -lt 0) -or ($vmindex_select -gt ($vmfound.count-1)))
    {
        $vmindex_select=read-host "Enter VM index (0 to" ($vmfound.count-1)") or -1 to quit"
        try
        {
            $vmindex_select=[int]::Parse($vmindex_select)
        }catch [System.FormatException]
        {
            write-host "Default index selected: 0"
            $vmindex_select = 0
        }

        if($vmindex_select -lt 0)
        {
            write-host "Operation cancelled" -ForegroundColor Green 
            exit
        }
    }

    $vmdisplay[$vmindex_select].object|select-object name,powerstate,numCpu,MemoryGB|format-table -AutoSize
    write-host "Open VM remote console:" $vmdisplay[$vmindex_select].Object -ForegroundColor Green 
    $vmdisplay[$vmindex_select].object|Open-MyVMConsoleWindow
}