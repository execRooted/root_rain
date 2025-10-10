# Raindrops

A beautiful terminal-based rain animation simulation written in Rust.

## Features

- Realistic raindrop animation with physics
- Multiple weather modes: normal, stormy, snowy
- Horizontal drift control (left/right)
- Color customization with gradient effects
- Continuity mode for seamless animation
- Smooth 200 FPS performance
- Cross-platform terminal support

## Installation

### From Source (Rust)

Ensure you have Rust installed, then clone and build:

```bash
git clone <repository-url>
cd raindrops
cargo build --release
```

### Arch Linux (AUR/PKGBUILD)

If you have the PKGBUILD file, install using makepkg:

```bash
cd raindrops
makepkg -si
```

This will build and install the package globally.

## Usage

Run the animation with default settings:

```bash
cargo run
```

### Command Line Options

- `-s, --speed <SPEED>`: Set animation speed (fast=1.5x, medium=1.0x, slow=0.5x)
- `-c, --color <COLOR>`: Set drop color (black, red, green, yellow, blue, magenta, cyan, white, grey)
- `-b, --bold`: Make drops bold
- `-w, --weather <WEATHER>`: Set weather type (rainy, snowy)
- `--direction <DIRECTION>`: Set horizontal drift (left, right, down)
- `--continuity`: Enable continuity mode (particles disappear instead of staying)
- `-l, --live [COLORS]`: Enable live effect (colors fade from color1 to color2 based on height, defaults to blue white if no colors specified)
- `--character <CHAR>`: Set all particles to a specific character

### Examples

Stormy weather with red gradient:
```bash
cargo run -- --weather storm --color red --gradient
```

Snow with left drift:
```bash
cargo run -- --weather snowy --direction left
```

Fast animation with continuity:
```bash
cargo run -- --speed fast --continuity
```

## Controls

- Press Ctrl+C to exit the animation

## Dependencies

- clap: Command line argument parsing
- crossterm: Terminal manipulation
- rand: Random number generation
- ctrlc: Signal handling

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

[Add license information here]