#Requires -Version 3.0 -Modules Hyper-V
function Get-MrVHDChain {

<#
.SYNOPSIS
    Gets the virtual hard disk chain associated with a virtual machine in HyperV.
 
.DESCRIPTION
    Get-MrVHDChain is an advanced function for determining the HyperV virtual disk object chain for one
    or more VMs (virtual machines).
 
.PARAMETER ComputerName
    Name of the Hyper-V host virtualization server that the specified VM's are running on. The default is
    the local system.

.PARAMETER Name
    The name of the VM(s) to determine the HyperV VHD or VHDX file chain for. The default is all VM's on
    the specified HyperV host.
 
.EXAMPLE
     Get-MrVHDChain -Name VM01, VM02, VM03

.EXAMPLE
     Get-MrVHDChain -ComputerName Server01

.EXAMPLE
     Get-MrVHDChain -ComputerName Server01 -Name VM01, VM02

.INPUTS
    None
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string[]]$Name = '*'
    )
    try {
        $VMs = Get-VM -ComputerName $ComputerName -Name $Name -ErrorAction Stop
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    foreach ($vm in $VMs){
        $VHDs = ($vm).harddrives.path
        foreach ($vhd in $VHDs){
            Clear-Variable VHDType -ErrorAction SilentlyContinue
            try {
                $VHDInfo = $vhd | Get-VHD -ComputerName $ComputerName -ErrorAction Stop
            }
            catch {
                $VHDType = 'Error'
                $VHDPath = $vhd
                Write-Verbose $_.Exception.Message
            }
            $i = 1
            $problem = $false
            while (($VHDInfo.parentpath -or $i -eq 1) -and (-not($problem))){
                If ($VHDType -ne 'Error' -and $i -gt 1){
                    try {
                        $VHDInfo = $VHDInfo.ParentPath | Get-VHD -ComputerName $ComputerName -ErrorAction Stop
                    }
                    catch {
                        $VHDType = 'Error'
                        $VHDPath = $VHDInfo.parentpath
                        Write-Verbose $_.Exception.Message
                    }
                }
                if ($VHDType -ne 'Error'){
                    $VHDType = $VHDInfo.VhdType
                    $VHDPath = $VHDInfo.path
                }
                else {
                    $problem = $true
                }
                [pscustomobject]@{
                    Name = $vm.name
                    VHDNumber = $i
                    VHDType = $VHDType
                    VHD = $VHDPath
                }
                $i++
            }
        }
    }
}