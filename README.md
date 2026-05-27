# PrepStation

A production-grade non-linear video editor built with Flutter, targeting iOS and macOS.

## Features

### Multi-track Timeline
- Unlimited video, audio, image, title, color card, and adjustment layer tracks
- Blade tool for splitting clips at the playhead
- Timeline markers and clip label colors for organization
- Clip locking and muting
- Linked/unlinked audio channels
- Undo/redo for all editing operations

### Clip Editing
- Trim in/out points with drag handles
- Speed adjustment
- Opacity control
- Flip horizontal and vertical
- Reverse playback
- Freeze frame
- Crop (left, right, top, bottom edges)
- Transform: position, scale, rotation, and anchor point
- Per-clip audio volume
- 17 blend modes: Normal, Multiply, Screen, Overlay, Add, Darken, Lighten, Color Dodge, Color Burn, Hard Light, Soft Light, Difference, Exclusion, Hue, Saturation, Color, Luminosity
- Right-click / long-press context menu for quick delete

### Keyframe Animation
Animate any of the following properties over time with bezier interpolation:
- Position (X, Y), scale (X, Y), rotation, anchor (X, Y)
- Opacity, speed, volume
- Crop edges (left, right, top, bottom)
- Individual effect parameters

### Transitions (30+)
Cross Dissolve, Fade to Black, Fade to White, Wipe (Left/Right/Up/Down), Slide (Left/Right/Up/Down), Circle Open/Close, Radial, Rectangle Crop, Distance, Fade Grays, Squeeze H/V, Zoom In, Wind (Left/Right), Cover (Left/Right/Up/Down), Reveal (Left/Right/Up/Down)

### Video Effects
| Effect | Description |
|---|---|
| Color Correction | Brightness, contrast, saturation, hue |
| Color Wheels | Lift, gamma, gain wheels |
| Curves | Luma and RGB channel curves |
| LUT | Apply a 3D Look-Up Table |
| Blur | Gaussian blur |
| Sharpen | Edge sharpening |
| Denoise | Temporal noise reduction |
| Vignette | Adjustable vignette |
| Film Grain | Cinematic grain overlay |
| Chroma Key | Green/blue screen keying |
| Stabilize | Motion stabilization |

### Audio Effects
| Effect | Description |
|---|---|
| Equalizer | Multi-band EQ |
| Compressor | Dynamics compression |
| Noise Reduction | Background noise removal |
| Reverb | Room reverb |

### Title & Text Clips
- Custom text, font size, text color, and background color
- Left, center, and right alignment
- Google Fonts integration
- Text animations: Fade In, Slide Up/Down/Left/Right, Zoom In, Typewriter

### Subject Isolation (Background Removal)
- Draw-to-select subject isolation powered by Apple Vision
- Output modes: Transparent, Blur Background, Solid Color
- Adjustable blur radius and edge feather
- Generates a mask video used for real-time compositing

### Subject Tracking
- Template-matching point tracker through any video clip
- Place a tracker pin at any point in the video; tracking runs forward and backward through the clip
- Attach any clip to a tracked object so its position follows automatically
- Configurable search radius and frame step

### Multi-layer Compositing
- Stack videos and images like cel animation
- Independent blend mode, opacity, and transform per layer

### Media Import
- File picker for video, audio, and image files
- Drag-and-drop import from the file system

### Export
**Presets**
- YouTube 1080p H.264
- YouTube 4K H.264
- Instagram Reels 9:16 H.264
- H.265 1080p
- VP9 WebM
- DNxHD 1080p (MOV)

**Custom export settings**
- Resolution and frame rate
- Video codec: H.264, H.265, VP9, passthrough
- Audio codec: AAC, MP3, Opus, PCM
- Container: MP4, WebM, MOV
- Bitrate and CRF control
- Real-time progress indicator

### Project Management
- Project browser with thumbnail previews
- SQLite-backed persistence (Drift ORM)
- Composition settings: resolution, frame rate, background color, pixel aspect ratio

## Requirements
- iOS 16+ or macOS 13+
- Flutter SDK ^3.11

## Getting Started

```sh
flutter pub get
flutter run
```

For macOS, ensure the app has network access enabled (required for Google Fonts) in the entitlements file.
