Idea: try running moonlight through gamescope, so I can keep Niri but fire up HDR moonlight.

W/H refers to the internal resolution
which is then scaled to w/h by gamescope
better compatability, less network overhead

```bash
PREFER_VULKAN=1 gamescope -W 2560 -H 1600 -w 2880 -h 1800 -r 120 -U -Y --hdr-enabled -- moonlight
```
