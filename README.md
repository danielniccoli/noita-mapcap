# Noita MapCapture addon [![Build Status](https://travis-ci.com/Dadido3/noita-mapcap.svg?branch=master)](https://travis-ci.com/Dadido3/noita-mapcap)

Addon that captures the map and saves it as image.

![](images/example1.png)

A resulting image with close to 3 gigapixels can be [seen here](https://easyzoom.com/image/158284/album/0/4) (Warning: Spoilers).

## System requirements

- Windows Vista, ..., 10 (64 bit version)
- A few GB of free drive space
- 16-32 GB of RAM (But works with less as long as the software doesn't run out of virtual memory)
- A processor
- Optionally a monitor, keyboard and mouse to interact with the mod/software
- A sound card to listen to music while it's grabbing screenshots

## Usage

1. Have Noita installed.
2. Download the [latest release of the mod from this link](https://github.com/Dadido3/noita-mapcap/releases/latest) (The `Windows.x86.7z`, not the source)
3. Unpack it into your mods folder, so that you get the following file structure `.../Noita/mods/noita-mapcap/mod.xml`.
4. Set your resolution to 1920x1080 if possible, and use the `Windowed` mode. (Not `Fullscreen (Windowed)`!) If you have to use a different resolution, see advanced usage.
5. Enable the mod and restart Noita.
6. In the game you should see a `>> Start capturing map <<` text on the screen, click it.
7. The screen will jump around, and the game will take screenshots automatically. Don't interfere with it. Screenshots are saved in `.../Noita/mods/noita-mapcap/output/`.
8. When you think you are done, close noita.
9. Start `.../Noita/mods/noita-mapcap/bin/stitch/stitch.exe`.
    - Use the default values to create a complete stitch.
    - It will take the screenshots from the `output` folder.
10. The result will be saved as `.../Noita/mods/noita-mapcap/bin/stitch/output.png` if not defined otherwise.

## Advanced usage

If you use `noita_dev.exe`, you can enable the debug mode by pressing `F5`. Once in debug mode, you can use `F8` to toggle shaders (Includes fog of war), and you can use `F12` to disable the UI. There are some more options in the `F7` and `Shift + F7` menu.

You can capture in a different resolution if you want or need to. If you do so, you have to adjust some values inside of the mod.

The following two formulae have to be true:

![CAPTURE_PIXEL_SIZE = SCREEN_RESOLUTION_* / VIRTUAL_RESOLUTION_*](https://latex.codecogs.com/png.latex?%5Cinline%20%5Cdpi%7B120%7D%20%5Clarge%20%5Cbegin%7Balign*%7D%20%5Ctext%7BCAPTURE%5C_PIXEL%5C_SIZE%7D%20%26%3D%20%5Cfrac%7B%5Ctext%7BSCREEN%5C_RESOLUTION%5C_X%7D%7D%7B%5Ctext%7BVIRTUAL%5C_RESOLUTION%5C_X%7D%7D%5C%5C%20%5Ctext%7BCAPTURE%5C_PIXEL%5C_SIZE%7D%20%26%3D%20%5Cfrac%7B%5Ctext%7BSCREEN%5C_RESOLUTION%5C_Y%7D%7D%7B%5Ctext%7BVIRTUAL%5C_RESOLUTION%5C_Y%7D%7D%20%5Cend%7Balign*%7D)

- Where `CAPTURE_PIXEL_SIZE` can be found inside `.../Noita/mods/noita-mapcap/files/capture.lua`
- `VIRTUAL_RESOLUTION_*` can be found inside `.../Noita/mods/noita-mapcap/files/magic_numbers.xml`
- and `SCREEN_RESOLUTION_*` is the screen resolution you have set up in noita.

If you have a resolution of `1366 x 768‎`, then you should change the `VIRTUAL_RESOLUTION_*` to `683 x 384`.
Another solution would be to change the `CAPTURE_PIXEL_SIZE` to `1.423`, but then you would get blurry images.

You can also change how much the tiles overlap by adjusting the `CAPTURE_GRID_SIZE` in `.../Noita/mods/noita-mapcap/files/capture.lua`. If you increase the grid size, you can capture more area per time. But on the other hand the stitcher may not be able to remove artifacts if the tiles don't overlap enough.

## License

[MIT](LICENSE)
