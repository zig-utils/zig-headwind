# Basic Landing Page Example

A simple landing page showcasing Zig Headwind's capabilities.

## Features Demonstrated

- **Responsive Design**: Mobile-first responsive layout using `sm:`, `md:` breakpoints
- **Dark Mode**: Full dark mode support with `dark:` variant
- **Interactive States**: Hover effects and transitions
- **Flexbox & Grid**: Modern layout utilities
- **Typography**: Font sizes, weights, and text styling
- **Colors**: Background, text, and border colors
- **Shadows**: Box shadows and elevation
- **Spacing**: Padding, margins, and gaps

## Build Instructions

From the repository root:

```bash
# Build the CSS
./zig-out/bin/headwind build examples/basic-landing-page/index.html -o examples/basic-landing-page/styles.css

# Watch for changes
./zig-out/bin/headwind watch examples/basic-landing-page/index.html -o examples/basic-landing-page/styles.css
```

## Usage

Open `index.html` in your browser to see the landing page.

To enable dark mode, add the `dark` class to the `<html>` element or use your browser's dark mode preference.
