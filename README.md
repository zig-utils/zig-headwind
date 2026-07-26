# Zig crosswind

A **blazing-fast** Tailwind CSS alternative built with Zig, achieving near feature-parity with Tailwind CSS.

## Features

🚀 **Blazing Fast** - Built with Zig for maximum performance
⚡ **Zero Node.js** - No JavaScript runtime required
🎯 **Type-Safe** - Compile-time safety guarantees
🔥 **Modern CSS** - OKLCH colors, container queries, color-mix()
🎨 **Tailwind Compatible** - Near complete feature parity
🧩 **Extensible** - Powerful plugin system

## Current Status

**Ready for v0.1.0** - Feature-complete for basic production use!

### ✅ Implemented Features

**Core System:**
- ✅ Full CLI with build, watch, init, check, clean commands
- ✅ CSS generation with @layer support (base, components, utilities)
- ✅ File scanning and HTML class extraction
- ✅ Configuration system with zig-config
- ✅ Intelligent file caching for fast rebuilds
- ✅ CSS minification

**Variant System (Complete):**
- ✅ Pseudo-classes: `hover:`, `focus:`, `active:`, `disabled:`, etc.
- ✅ Pseudo-elements: `before:`, `after:`, `placeholder:`, `selection:`
- ✅ Responsive breakpoints: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`
- ✅ Dark mode: `dark:` (class and media strategies)
- ✅ Container queries: `@sm:`, `@md:`, `@lg:`, `@xl:`, `@2xl:`
- ✅ Group variants: `group-hover:`, `group/name-hover:`
- ✅ Peer variants: `peer-focus:`, `peer/name-checked:`
- ✅ Important modifier: `!`

**Utilities (Comprehensive):**

*Layout & Flexbox:*
- ✅ Display, position, overflow, z-index, isolation, visibility
- ✅ Flexbox (flex, flex-direction, flex-wrap, align-items, justify-content, gap)
- ✅ Grid (grid, grid-cols, grid-rows, gap, grid-flow)
- ✅ Container

*Spacing:*
- ✅ Padding (`p-*`, `px-*`, `py-*`, `pt-*`, `pr-*`, `pb-*`, `pl-*`)
- ✅ Margin (`m-*`, `mx-*`, `my-*`, `mt-*`, `mr-*`, `mb-*`, `ml-*`)
- ✅ Negative margins (`-m-*`, `-mt-*`, etc.)
- ✅ Gap (`gap-*`, `gap-x-*`, `gap-y-*`)
- ✅ Arbitrary values (`p-[20px]`, `m-[1.5rem]`)

*Typography (20+ utility sets):*
- ✅ Font family, size, weight, style
- ✅ Text alignment, decoration, transform, overflow
- ✅ Line height, letter spacing
- ✅ Whitespace, text wrap, word break
- ✅ Vertical align, text indent

*Colors:*
- ✅ Full Tailwind color palette (slate, gray, red, blue, green, yellow, etc.)
- ✅ Background, text, border colors
- ✅ OKLCH color space support
- ✅ color-mix() for modern browsers
- ✅ Arbitrary color values (`bg-[#ff5733]`, `text-[rgb(255,0,0)]`)

*Sizing:*
- ✅ Width, height, min-width, max-width, min-height, max-height
- ✅ Arbitrary sizing (`w-[100px]`, `h-[75vh]`, `w-[50%]`)

*Borders:*
- ✅ Border width, style, radius, color
- ✅ Outline, ring, divide utilities

*Backgrounds:*
- ✅ Background color, size, position, repeat
- ✅ Gradients (to-r, to-br, from-*, via-*, to-*)
- ✅ Background attachment, clip, origin

*Effects:*
- ✅ Box shadow, drop shadow, text shadow
- ✅ Opacity, mix-blend-mode
- ✅ Filters (blur, brightness, contrast, grayscale, hue-rotate, invert, saturate, sepia)
- ✅ Backdrop filters

*Transforms & Animations:*
- ✅ Scale, rotate, translate, skew, transform-origin
- ✅ Transitions (property, duration, timing, delay)
- ✅ Animations (spin, ping, pulse, bounce)

*Interactivity:*
- ✅ Cursor, pointer-events, resize, scroll-behavior
- ✅ User-select, will-change, accent-color, caret-color, appearance

**Modern CSS Features:**
- ✅ OKLCH colors with Safari fallbacks
- ✅ Container queries (`@container`)
- ✅ text-shadow with modern syntax
- ✅ color-mix() for color blending

**Plugins:**
- ✅ Typography plugin (@tailwindcss/typography)
- ✅ Forms plugin (@tailwindcss/forms)
- ✅ Prose styles for rich content

### 🚧 Remaining Work
- Memory leak improvements (non-critical, mostly in test environments)
- Additional typography utilities (text-indent, hyphens, text-start/text-end)
- Performance optimizations (multi-threading, SIMD)

See [NEXT_STEPS.md](NEXT_STEPS.md) for the detailed roadmap.

## Installation

### From Source (Current)

```bash
git clone https://github.com/yourusername/crosswind.git
cd crosswind
zig build
```

### Via npm (Coming Soon)

```bash
npm install -g @crosswind/crosswind
```

### Via Homebrew (Coming Soon)

```bash
brew install crosswind
```

## Quick Start

### 1. Initialize a new project

```bash
./zig-out/bin/crosswind init
```

This creates a `crosswind.config.json` file with sensible defaults.

### 2. Create an HTML file

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="crosswind.css">
</head>
<body>
    <div class="flex items-center justify-center min-h-screen bg-gray-100">
        <div class="p-8 bg-white rounded-lg shadow-lg">
            <h1 class="text-3xl font-bold text-gray-900 mb-4">
                Hello crosswind!
            </h1>
            <p class="text-gray-600 mb-6">
                A blazing-fast Tailwind alternative built with Zig.
            </p>
            <button class="px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors">
                Get Started
            </button>
        </div>
    </div>
</body>
</html>
```

### 3. Build your CSS

```bash
./zig-out/bin/crosswind build index.html -o crosswind.css
```

### 4. Watch for changes

```bash
./zig-out/bin/crosswind watch index.html -o crosswind.css
```

## Usage Examples

### Basic Utilities

```html
<!-- Layout & Flexbox -->
<div class="flex flex-col items-center justify-between gap-4">
    <div class="w-full md:w-1/2 lg:w-1/3"></div>
</div>

<!-- Spacing -->
<div class="p-4 m-2 -mt-4 space-y-2"></div>

<!-- Typography -->
<h1 class="text-3xl font-bold leading-tight tracking-wide">Title</h1>
<p class="text-gray-600 italic line-through">Text</p>

<!-- Colors -->
<div class="bg-blue-500 text-white border-2 border-gray-300"></div>
```

### Variants

```html
<!-- Hover & Focus -->
<button class="bg-blue-500 hover:bg-blue-600 focus:ring-4 focus:ring-blue-300">
    Button
</button>

<!-- Responsive -->
<div class="text-sm md:text-base lg:text-lg xl:text-xl">
    Responsive text
</div>

<!-- Dark Mode -->
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
    Dark mode support
</div>

<!-- Container Queries -->
<div class="@container">
    <div class="text-base @md:text-lg @lg:text-xl">
        Container-aware text
    </div>
</div>

<!-- Group Hover -->
<div class="group">
    <img class="group-hover:scale-110 transition-transform">
    <p class="group-hover:text-blue-600">Hover me</p>
</div>

<!-- Named Groups -->
<div class="group/card">
    <div class="group/card-hover:opacity-100">
        Only shows on card hover
    </div>
</div>
```

### Arbitrary Values

```html
<!-- Custom sizes -->
<div class="w-[347px] h-[73vh] p-[1.5rem]"></div>

<!-- Custom colors -->
<div class="bg-[#ff5733] text-[rgb(255,0,0)] border-[#00ff00]"></div>

<!-- With variants -->
<div class="hover:w-[150px] md:h-[300px] dark:bg-[#0000ff]"></div>
```

### Modern CSS Features

```html
<!-- OKLCH Colors (with fallbacks) -->
<div class="bg-blue-500"></div>
<!-- Generates: background-color: oklch(0.54 0.23 262) or #3b82f6 -->

<!-- Container Queries -->
<div class="@container">
    <div class="@sm:text-lg @md:text-xl @lg:text-2xl">
        Responsive to container, not viewport
    </div>
</div>

<!-- color-mix() -->
<div class="bg-blue-500/50"></div>
<!-- Generates: background-color: color-mix(in oklch, oklch(0.54 0.23 262) 50%, transparent) -->
```

### Negative Values

```html
<!-- Negative margins -->
<div class="-m-4 -mt-2 -mx-8"></div>
<div class="-m-[20px]"></div>

<!-- Pull elements up -->
<img class="-mt-16" />
```

## Configuration

crosswind uses [zig-config](https://github.com/stacksjs/zig-config) for configuration management, supporting multiple formats and sources.

### Configuration File

Create `crosswind.config.json` in your project root:

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
    "output": "dist/crosswind.css",
    "minify": true,
    "sourcemap": true
  },
  "plugins": []
}
```

### Environment Variables

Override configuration with environment variables:

```bash
export crosswind_BUILD_MINIFY=true
export crosswind_BUILD_OUTPUT=dist/styles.css
crosswind build
```

### Configuration Schema

```zig
pub const crosswindConfig = struct {
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
crosswind build          # Build CSS from source files
crosswind watch          # Watch for changes and rebuild (coming soon)
crosswind init           # Initialize configuration file
crosswind check          # Validate configuration
crosswind clean          # Clean cache
crosswind version        # Show version information
crosswind help           # Show help message
```

## Architecture

crosswind is designed with performance and safety in mind:

### Core Modules

- **Core** - Fundamental types and memory management
- **Config** - Configuration loading and validation
- **Scanner** - File system scanning and class extraction
- **Parser** - CSS class name parsing and validation
- **Generator** - CSS rule generation and optimization
- **Cache** - Intelligent caching system
- **CLI** - Command-line interface

### Memory Management

crosswind uses Zig's allocator system with:
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
crosswind/
├── src/
│   ├── main.zig              # CLI entry point
│   ├── crosswind.zig          # Library entry point
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

## Community

For help, discussion about best practices, or any other conversation that would benefit from being searchable:

[Discussions on GitHub](https://github.com/cwcss/zig-crosswind/discussions)

For casual chit-chat with others using this package:

[Join the Stacks Discord Server](https://stacksjs.com/discord)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [Tailwind CSS](https://tailwindcss.com)
- Inspired by [UnoCSS](https://unocss.dev)
- Built with [Zig](https://ziglang.org)
- Configuration powered by [zig-config](https://github.com/stacksjs/zig-config)

## Links

- Documentation: [Coming Soon]
- GitHub: https://github.com/yourusername/crosswind
- Discord: [Coming Soon]

---

Built with ❤️ and Zig
