# Requires youtube-dl, ffmpeg
# Parameters:
#   -i : parameter file
#   -o : output file
#   -rmtmpfiles: Whether to remove the temporary files (Y/N)

param (
    [Parameter(Mandatory=$true)] $i,
    [Parameter(Mandatory=$true)] $o,
    [Parameter()] $rmtmpfiles = 'Y'
)

$tmp_file_prefix = 'tmp_'
$tmp_file_counter = 0
$tmp_file_suffix = '.ts'

$gen_files = @()
foreach($line in Get-Content $i) {
    $line_arr = $line.Split()
    if($line_arr.count -lt 3) {
        continue
    }
    $link = $line_arr[0]
    $start = $line_arr[1]
    $end = $line_arr[2]

    if($link.StartsWith("#")) {
        continue
    }

    if($link.Contains('bilibili')) {
        $filename = $tmp_file_prefix + $tmp_file_counter + $tmp_file_suffix
        $tmp_file_counter = $tmp_file_counter + 1;
        $dl_link = (youtube-dl -g $link) | Out-String

        if(!$dl_link) {
            exit
        }

        if($start -eq "00:00:00") {
            ffmpeg -y -i $dl_link -t $end -c copy -f mpegts $filename
        } else {
            ffmpeg -y -ss $start -i $dl_link -t $end -c copy -f mpegts $filename
        }
        
        $gen_files += $filename
    } elseif ($link.Contains('youtube') -or $link.Contains('youtu.be')) {
        $filename = $tmp_file_prefix + $tmp_file_counter + $tmp_file_suffix
        $tmp_file_counter = $tmp_file_counter + 1;
        $links = (youtube-dl -g $link) | Out-String

        if(!$links) {
            exit
        }

        $links = $links.Split([Environment]::NewLine)
        
        $video = $links[0]
        $audio = $links[2]

        if($start -eq "00:00:00") {
            ffmpeg -y -i $video -i $audio -t $end -map "0:v" -map 1:a -"c:v" libx264 -"c:a" aac -f mpegts $filename
        } else {
            ffmpeg -y -ss $start -i $video -ss $start -i $audio -t $end -map "0:v" -map 1:a -"c:v" libx264 -"c:a" aac -f mpegts $filename
        }

        $gen_files += $filename
    } else {
        continue
    }
}

$filenames = $gen_files -join "|"
ffmpeg -i "concat:$filenames" -c copy $o

if ($rmtmpfiles -eq 'Y') {
    foreach($gen_file in $gen_files) {
        Remove-Item $gen_file
    }
}