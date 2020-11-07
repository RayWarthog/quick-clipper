# quick-clipper
Powershell script to download and merge youtube/bilibili clips. 
The script utilizes youtube-dl to extract the links, and use ffmpeg to download and merge it.

Warning that this script doesn't handle much errors, and may leave half-finished tmp_* files if it failed halfway.

## Requires
* ffmpeg
* youtube-dl

## Usage
1. Create a paramater txt file containing list of clips in the following format
```
# Lines starting with '#' are ignored
https://www.youtube.com/watch?v=dQw4w9WgXcQ 00:00:43 00:00:08
```

You can refer to the sample_input.txt file

2. Run it in PowerShell
```powershell
.\quick_clips.ps1 -i example_input.txt -o output.mp4
```

3. Find the merged video in the same directory this script is ran.
