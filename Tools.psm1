# tools module

function CopyFiles 
{
    Param( [string] $srcPath, [string] $dscPath)

    Write-Host "Copy files from $srcPath to $dscPath ..."

    $cl = Get-Location
    
    if ($false -eq $(Test-Path $dscPath))
    {
        New-Item -Path $dscPath -ItemType Directory -Force
    }
    Set-Location $dscPath
    
    Get-ChildItem -Path $srcPath | % { Copy-Item $_.FullName -Recurse -Force }
    
    Set-Location $cl

    Write-Host "Copy files done."
}
