# Headwind

A high-performance Tailwind CSS alternative built with Zig, targeting feature parity with Tailwind 4.1.

## Features

🚀 **Blazing Fast** - Built with Zig for maximum performance
⚡ **Zero Dependencies** - No Node.js required (optional npm wrapper for convenience)
🎯 **Type-Safe** - Compile-time safety guarantees
🔥 **Hot Reload** - Lightning-fast rebuilds with intelligent caching
🎨 **Tailwind Compatible** - Designed for feature parity with Tailwind 4.1
🧩 **Extensible** - Powerful plugin system

## Current Status

This project is in **active development**. Phase 1 (Project Setup & Core Architecture) is complete.

See [TODO.md](TODO.md) for the comprehensive implementation roadmap.

## Installation

### From Source (Current)

```bash
git clone https://github.com/yourusername/headwind.git
cd headwind
zig build
```

### Via npm (Coming Soon)

```bash
npm install -g @headwind/headwind
```

### Via Homebrew (Coming Soon)

```bash
brew install headwind
```

## Quick Start

### 1. Initialize a new project

```bash
headwind init
```

This creates a `headwind.config.json` file:

```json
{
  "content": {
    "files": [
      "src/**/*.{html,js,jsx,ts,tsx,vue,svelte}"
    ]
  },
  "theme": {
    "extend": {}
  },
  "plugins": []
}
```

### 2. Build your CSS

```bash
headwind build
```

### 3. Watch for changes (Coming Soon)

```bash
headwind watch
```

## Configuration

Headwind uses [zig-config](https://github.com/stacksjs/zig-config) for configuration management, supporting multiple formats and sources.

### Configuration File

Create `headwind.config.json` in your project root:

```json
{
  "content": {
    "files": ["src/**/*.{html,js,jsx,ts,tsx}"],
    "exclude": ["node_modules/**", "dist/**"]
  },
  "theme": {
    "colors": {
      "primary": "#3b82f6",
      "secondary": "#8b5cf6"
    },
    "extend": {
      "spacing": {
        "128": "32rem"
      }
    }
  },
  "darkMode": {
    "strategy": "class",
    "className": "dark"
  },
  "build": {
    "output": "dist/headwind.css",
    "minify": true,
    "sourcemap": true
  },
  "plugins": []
}
```

### Environment Variables

Override configuration with environment variables:

```bash
export HEADWIND_BUILD_MINIFY=true
export HEADWIND_BUILD_OUTPUT=dist/styles.css
headwind build
```

### Configuration Schema

```zig
pub const HeadwindConfig = struct {
    content: ContentConfig,
    theme: ThemeConfig,
    build: BuildConfig,
    darkMode: DarkModeConfig,
    plugins: []PluginConfig,
    prefix: []const u8 = "",
    separator: []const u8 = ":",
};
```

See [src/config/schema.zig](src/config/schema.zig) for the full schema.

## CLI Commands

```bash
headwind build          # Build CSS from source files
headwind watch          # Watch for changes and rebuild (coming soon)
headwind init           # Initialize configuration file
headwind check          # Validate configuration
headwind clean          # Clean cache
headwind version        # Show version information
headwind help           # Show help message
```

## Architecture

Headwind is designed with performance and safety in mind:

### Core Modules

- **Core** - Fundamental types and memory management
- **Config** - Configuration loading and validation
- **Scanner** - File system scanning and class extraction
- **Parser** - CSS class name parsing and validation
- **Generator** - CSS rule generation and optimization
- **Cache** - Intelligent caching system
- **CLI** - Command-line interface

### Memory Management

Headwind uses Zig's allocator system with:
- Arena allocators for request-scoped memory
- String interning for deduplication
- Object pools for reusable allocations
- Zero-copy parsing where possible

### Performance Features

- Multi-threaded file scanning
- Lock-free cache data structures
- SIMD-accelerated string matching (planned)
- Incremental builds with smart caching
- Parallel CSS generation

## Development

### Prerequisites

- Zig 0.12.0 or later
- [zig-config](https://github.com/stacksjs/zig-config) (included as dependency)

### Build

```bash
# Build the project
zig build

# Run tests
zig build test

# Run benchmarks
zig build bench

# Format code
zig build fmt

# Cross-compile for all platforms
zig build cross
```

### Project Structure

```
headwind/
├── src/
│   ├── main.zig              # CLI entry point
│   ├── headwind.zig          # Library entry point
│   ├── core/                 # Core types and utilities
│   │   ├── types.zig
│   │   └── allocator.zig
│   ├── config/               # Configuration system
│   │   ├── schema.zig
│   │   └── loader.zig
│   ├── scanner/              # File scanning (planned)
│   ├── parser/               # CSS parsing (planned)
│   ├── generator/            # CSS generation (planned)
│   ├── cache/                # Caching system (planned)
│   ├── cli/                  # CLI utilities (planned)
│   └── utils/                # Shared utilities
│       └── string.zig
├── test/                     # Tests
├── examples/                 # Example projects
├── build.zig                 # Build configuration
├── build.zig.zon            # Dependency configuration
└── TODO.md                   # Implementation roadmap
```

## Roadmap

See [TODO.md](TODO.md) for the comprehensive roadmap with 650+ tasks organized into 17 phases.

### Phase 1: ✅ Complete
- Project setup and build system
- Core architecture
- Configuration system with zig-config
- Memory management utilities
- String utilities
- CLI framework

### Phase 2-17: 🚧 Planned
- CSS scanning and parsing
- Utility class system
- Variant system
- Modern CSS features (Tailwind 4.1)
- Plugin system
- Performance optimization
- Testing and benchmarks
- Documentation and tooling
- Ecosystem integration

## Benchmarks (Planned)

Target performance metrics vs Tailwind CSS:
- 10x faster cold start
- 5x faster incremental builds
- 50% lower memory usage
- Sub-millisecond class extraction

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [Tailwind CSS](https://tailwindcss.com)
- Inspired by [UnoCSS](https://unocss.dev)
- Built with [Zig](https://ziglang.org)
- Configuration powered by [zig-config](https://github.com/stacksjs/zig-config)

## Links

- Documentation: [Coming Soon]
- GitHub: https://github.com/yourusername/headwind
- Discord: [Coming Soon]

---

Built with ❤️ and Zig
