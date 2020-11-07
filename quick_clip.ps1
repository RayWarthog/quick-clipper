# Requires youtube-dl, ffmpeg
# Parameters:
#   -i : parameter file
#   -o : output file
#   -rmtmpfiles: Whether to remove the temporary files (Y/N)

param (
    [Parameter(Mandatory = $true)] $i,
    [Parameter(Mandatory = $true)] $o,
    [string][Parameter()] $rmtmpfiles = 'Y'
)

$tmp_file_prefix = 'tmp_'
$tmp_file_counter = 0
$tmp_file_suffix = '.ts'

$gen_files = @()

$links_dict = @{}

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

    if ($link.Contains('bilibili')) {
        $filename = $tmp_file_prefix + $tmp_file_counter + $tmp_file_suffix
        $tmp_file_counter = $tmp_file_counter + 1;

        if($links_dict.ContainsKey($link)) {
            $dl_link = $links_dict[$link]
        } else {
            $dl_link = (youtube-dl -g $link) | Out-String
            $links_dict[$link] = $dl_link
        }

        if (!$dl_link) {
            exit
        }

        if ($start -eq '00:00:00') {
            ffmpeg -y -to $end -i $dl_link -c copy -f mpegts $filename
        } else {
            ffmpeg -y -ss $start -to $end -i $dl_link -c copy -f mpegts $filename
        }
        
        $gen_files += $filename
    }
    elseif ($link.Contains('youtube') -or $link.Contains('youtu.be')) {
        $filename = $tmp_file_prefix + $tmp_file_counter + $tmp_file_suffix
        $tmp_file_counter = $tmp_file_counter + 1;

        if($links_dict.ContainsKey($link)) {
            $links = $links_dict[$link]
        } else {
            $links = (youtube-dl -g $link) | Out-String
            $links_dict[$link] = $links
        }

        if (!$links) {
            exit
        }

        $links = $links.Split([Environment]::NewLine)
        
        $video = $links[0]
        $audio = $links[2]

        ffmpeg -y -ss $start -to $end -i $video -ss $start -to $end -i $audio -map "0:v" -map 1:a -"c:v" libx264 -"c:a" aac -f mpegts $filename

        $gen_files += $filename
    }
    elseif (Test-Path $link) {
        $filename = $tmp_file_prefix + $tmp_file_counter + $tmp_file_suffix
        $tmp_file_counter = $tmp_file_counter + 1;

        ffmpeg -y -ss $start -to $end -i $link -c copy -f mpegts $filename

        $gen_files += $filename
    }
    else {
        continue
    }
}

$filenames = $gen_files -join "|"
ffmpeg -i "concat:$filenames" -c copy $o

if ($rmtmpfiles -eq 'Y') {
    foreach ($gen_file in $gen_files) {
        Remove-Item $gen_file
    }
}
