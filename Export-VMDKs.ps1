<#  
.SYNOPSIS 
    Export all VMDKs for a named Datacenter to a CSV
.DESCRIPTION
    Run this script to export a list of all Hard Disk objects assigned to all VMs
    in the specified vSphere Datacenter.  The resulting CSV is ready for editing
    to map out target datastore objects for a Storage vMotion script to be created
    by Create-MigrationScript.ps1
.NOTES
    Author: Allen Derusha
#>

################################################################################
# Define values for script execution
$strOutputFile = "VMDK-Migration.csv"
$strSourceDatacenter = "Datacenter"
$strVCenterServer = "vcenter"

################################################################################
# Include required VMware Snapins
$snapin="VMware.VimAutomation.Core"
if (Get-PSSnapin $snapin -ErrorAction "SilentlyContinue") {
    # Write-Host "PSsnapin $snapin is loaded"
}
elseif (Get-PSSnapin $snapin -registered -ErrorAction "SilentlyContinue") {
    # Write-Host "PSsnapin $snapin is registered but not loaded"
    Add-PSSnapin $snapin
}
else {
    throw "Required PSSnapin $snapin not found"
}

# Connect to vCenter instance if we aren't already
if ($global:DefaultVIServers.Count -lt 1) {
    Connect-VIServer -Server $strVCenterServer -Protocol https
}

$myOutTable = @()

ForEach ($myVMDK in Get-Datacenter -Name $strSourceDatacenter | Get-VM | Get-HardDisk | Sort-Object Parent, Name) { 
	$myOutRecord = "" | Select-Object VMName, HDDName, Size, Filename, SourceDatastore, TargetDatastore
    $myOutRecord.VMName = $myVMDK.Parent
	$myOutRecord.Filename = $myVMDK.Filename
	$myOutRecord.Size = $myVMDK.CapacityGB
	$myOutRecord.HDDName = $myVMDK.Name
	$myOutRecord.SourceDatastore = $myVMDK.Filename -replace "\[(.*?)\].*",'$1'
	$myOutTable += $myOutRecord 
} 

$myOutTable | Export-Csv -Path $strOutputFile -NoTypeInformation