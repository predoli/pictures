# Digital Photo Frame Frontend

A Vue.js + Tauri desktop application for displaying images from the photo frame backend.

## Features

- 15-second automatic slideshow with smooth transitions
- Pause/Play controls
- Multiple ordering modes: Name (asc/desc), Date (asc/desc), Random
- Automatic pagination - loads more images as needed
- Keyboard shortcuts: Space (pause), Arrow keys (navigate)
- Fullscreen support
- Desktop application with Tauri

## Development

### Prerequisites

- Node.js 18+
- Rust (for Tauri)
- Photo frame backend running on `http://localhost:8080`

### Install dependencies

```bash
npm install
```

### Development server

```bash
npm run dev
```

### Build for desktop

```bash
npm run tauri:dev  # Development mode
npm run tauri:build  # Production build
```

## Project Structure

```
src/
├── components/
│   └── PhotoFrame.vue      # Main photo frame component
├── composables/
│   └── usePhotoFrame.ts    # Photo frame logic
├── types.ts                # TypeScript types from OpenAPI
├── App.vue                 # Root component
├── main.ts                 # Entry point
└── style.css              # Global styles

src-tauri/                  # Tauri desktop app configuration
├── src/
│   └── main.rs            # Rust main file
├── Cargo.toml             # Rust dependencies
└── tauri.conf.json        # Tauri configuration
```

## Keyboard Shortcuts

- **Space**: Pause/Play slideshow
- **Arrow Left**: Previous image
- **Arrow Right**: Next image

## API Integration

The frontend communicates with the backend API at `http://localhost:8080/images` with the following parameters:

- `count`: Number of images to fetch (1-100)
- `ordering`: Sort order (name_asc, name_desc, date_asc, date_desc, random)
- `last_image`: For pagination continuation

## Desktop App

Built with Tauri for cross-platform desktop deployment:

- **Windows**: `.exe` installer
- **macOS**: `.dmg` bundle  
- **Linux**: `.deb` / `.AppImage`

The app allows HTTP requests to the local backend server and provides a native desktop experience.