# `sceye` to `mp4`

A quick hacked up, reverse engineered script to turn the proprietry `sceye` video format to an `mp4`. This does not extract any other sensor data.

I have not extensively tested this on many files, but hopefully it is useful for you!

## Constraints

This script was designed to work on a semi locked down system without administrative persmissions.

## Requirements

1. Download both of these scripts into their own folder.
2. Download an `ffmpeg` binary and place it into the folder. You can find prebuild `ffmpeg` binaries [here](https://ffmpeg.org/download.html#build-windows).
3. Download `extractjpeg` from [here](https://www.gunamoi.com.au/soft/extractjpeg/index.html) and place it into the folder.

## Basic Usage

For basic usage, drag and drop a `sceye` file onto `sceye2mp4.bat`. This will produce a `mp4` file of the same name, which plays at 1/10 speed.

## Observations lf the `sceye` format

From the limited observed files, the `sceye` format consists for a fixed offser `json` header and embedded `jpeg` files. The header contains a framerate that the images were taken at.

`scrye2mp4.ps1` extracts and reads tbe `json` from the fixed offset before delegating to `extractjpeg` and `ffmepg` to extract and produce the `mp4`.

## Advanced Usage

This requires some experience of powershell. The `sceye2mp4.ps1` script comes with 3 additional arguments: `-FPSMultiplier`, `-Force` and `-Cache`. 

`-FPSMultipler` is self explanitory. If you set this too low,the video will be choppy because there isn't enough data.

### `-Cache`

`sceye2mp4.ps1` uses temporary folders to store the extracted `jpeg` files. After producing the `mp4` it deletes and cleans up these files. 

The `-Cache` flag disables the cleanup, leaving the individual `jpeg` files.

### `-Force` 

By default the script is cautious to not overwrite any existing files. 

This is normally not an issue, apart from when using the `-Cache` flag on a subsiquent file of the same name but shorter length. In this case the output `mp4` file will contain the end of the first time. 

`-Force` is most useful when you want to overwrite a file with with a different `FPSMultiplier`. 
