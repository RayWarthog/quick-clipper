<#
.SYNOPSIS
    Powershell script to download and merge youtube/bilibili clips.
.DESCRIPTION
    Given a parameter input file, the script utilizes youtube-dl to extract the links, and use ffmpeg to download and merge it.

    The parameter file should have lines that are in the specific format:
    <youtube/bilibili link> <start time> <end time>

    Requires youtube-dl, ffmpeg.
.PARAMETER i
    Parameter file
.PARAMETER o
    Output file
.Parameter rmtmpfiles
    If set, removes the temporary files generated
.Parameter noreuse
    If set, will not reuse previously downloaded clips and always redownload
.Parameter overwrite
    If set, skip the overwrite warning for output file
.NOTES
    Author: RayWarthog
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
            if ( -Not ($_ | Test-Path) ) {
                throw "Parameter file does not exist"
            }
            return $true
        })]
    [System.IO.FileInfo]
    $i,
    [Parameter(Mandatory = $true)][System.IO.FileInfo] $o,
    [Parameter(Mandatory = $false)][switch] $rmtmpfiles,
    [Parameter(Mandatory = $false)][switch] $noreuse,
    [Parameter(Mandatory = $false)][switch] $overwrite
)

$tmp_folder = 'tmp'
$tmp_file_suffix = '.ts'

$links_dict = @{}
$gen_files = @()
$to_merge_files = @()

if (!(Test-Path $tmp_folder)) {
    Write-Host "Creating temporary folder $tmp_foldeer..."
    New-Item -ItemType Directory -Force -Path $tmp_folder
}

foreach ($line in Get-Content $i) {
    $line_arr = $line.Split()
    if ($line_arr.count -lt 3) {
        continue
    }
    $link = $line_arr[0]
    $start = $line_arr[1]
    $end = $line_arr[2]

    if ($link.StartsWith("#")) {
        continue
    }

    "[$link $start $end]"

    $tmp_file_name = ($link.substring(0, [System.Math]::Min(180, $link.Length)) + '_' + $start + '_' + $end).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $tmp_file_path = $tmp_folder + '/' + $tmp_file_name + $tmp_file_suffix

    if (!($noreuse) -and (Test-Path $tmp_file_path)) {
        Write-Host "Clip already exists, skipping processing."
        $to_merge_files += $tmp_file_path
        continue
    }

    if ($link.Contains('bilibili')) {
        Write-Host "Processing bilibili link..."
        if ($links_dict.ContainsKey($link)) {
            $dl_link = $links_dict[$link]
        }
        else {
            $dl_link = (youtube-dl -g $link) | Out-String
            $links_dict[$link] = $dl_link
        }

        if (!$dl_link) {
            exit
        }

        if ($start -eq '00:00:00') {
            ffmpeg -y -to $end -i $dl_link -"c:v" libx264 -"c:a" aac -f mpegts $tmp_file_path
        }
        else {
            ffmpeg -y -ss $start -to $end -i $dl_link -"c:v" libx264 -"c:a" aac -f mpegts $tmp_file_path
        }
        
        $gen_files += $tmp_file_path
        $to_merge_files += $tmp_file_path
    }
    elseif ($link.Contains('youtube') -or $link.Contains('youtu.be')) {
        Write-Host "Processing youtube link..."
        if ($links_dict.ContainsKey($link)) {
            $links = $links_dict[$link]
        }
        else {
            $links = (youtube-dl -g $link) | Out-String
            $links_dict[$link] = $links
        }

        if (!$links) {
            exit
        }

        $links = $links.Split([Environment]::NewLine)
        
        $video = $links[0]
        $audio = $links[2]

        ffmpeg -y -ss $start -to $end -i $video -ss $start -to $end -i $audio -map "0:v" -map 1:a -"c:v" libx264 -"c:a" aac -f mpegts $tmp_file_path

        $gen_files += $tmp_file_path
        $to_merge_files += $tmp_file_path
    }
    elseif (Test-Path $link) {
        Write-Host "Processing local file..."
        ffmpeg -y -ss $start -to $end -i $link -c copy -f mpegts $tmp_file_path

        $gen_files += $tmp_file_path
        $to_merge_files += $tmp_file_path
    }
    else {
        Write-Host "Attempting to process..."

        ffmpeg -y -ss $start -to $end -i $link -c copy -f mpegts $tmp_file_path

        $gen_files += $tmp_file_path
        $to_merge_files += $tmp_file_path
    }
}

Write-Host "Merging..."
$filenames = $to_merge_files -join "|"
if ($overwrite) {
    ffmpeg -y -i "concat:$filenames" -c copy $o
}
else {
    ffmpeg -i "concat:$filenames" -c copy $o
}

if ($rmtmpfiles) {
    Write-Host "Removing generated files..."
    foreach ($gen_file in $gen_files) {
        Remove-Item $gen_file
    }

    $tmp_folder_info = Get-ChildItem $tmp_folder | Measure-Object
    if ($tmp_folder_info.count -eq 0) {
        Write-Host "Removing $tmp_folder..."
        Remove-Item $tmp_folder
    }
}

Write-Host "Done."
