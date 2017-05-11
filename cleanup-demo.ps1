Write-Output "Cleanup SqlDemo environment"

$vms = Get-Vm -Name SqlDemo*

foreach( $vm in $vms)
{
    Stop-Vm $vm -Confirm -Force
    remove-vm $vm -Force
}

foreach( $vhd in {"pdc.vhd", "sql01.vhd", "sql02.vhd"} )
{
    $path = ".\vm\$_"

    if (Test-Path $path) 
    { 
        Remove-Item $path 
    }
}