# mount disk and copy files
param($ImagePath, $SrcPath, $DstPath)

$list = Get-PSDrive -PSProvider FileSystem

try
{
    Mount-DiskImage -ImagePath $ImagePath
    $list2 = Get-PSDrive -PSProvider FileSystem

    $ImageDrive = $list2 | ? { !$list.Contains($_) }

    $SrcPath = Join-Path $ImageDrive.Root -ChildPath $SrcPath
    $SrcPath
    if (!(Test-Path $SrcPath))
    {
        Write-Error "Can't find source path"
    }
    else
    {
        if (!(Test-Path $DstPath))
        {
            New-Item $DstPath -ItemType Directory
        }
        Write-Host $SrcPath + " : " + $DstPath
        Copy-Item -Path $SrcPath -Destination $DstPath -Recurse
    }
}
finally
{
    Dismount-DiskImage -ImagePath $ImagePath
}


