# quick-clipper
Powershell script to download and merge youtube/bilibili clips. 
The script utilizes youtube-dl to extract the links, and use ffmpeg to download and merge it.

By default, clips will be downloaded to a tmp folder, before they are merged.
The tmp folder and the downloaded clips wouldn't be removed (unless the -rmtmpfiles flag is set), and the clips inside may be reused if the script is called again (unless the -noreuse flag is set).

Warning that this script doesn't handle much errors, and may leave half-finished files at the tmp folder if it failed halfway.

## Requires
* ffmpeg
* youtube-dl

## Usage
1. Create a paramater txt file containing list of clips in the following format
    ```
    # Lines starting with '#' are ignored
    # <youtube/bilibili link> <start time> <end time>
    https://www.youtube.com/watch?v=dQw4w9WgXcQ 00:00:43 00:00:50

    # Refer to the example_input.txt file
    ```

2. Run it in PowerShell
    ```powershell
    .\quick_clips.ps1 -i example_input.txt -o output.mp4
    ```

3. Find the merged video in the same directory this script is ran.

To see other available parameters
```powershell
Get-Help .\quick_clip.ps1 -detailed
```
