const std = @import("std");
const string_utils = @import("../utils/string.zig");
const simd = @import("../utils/simd.zig");

/// Grouped Syntax Parser (UnunuraCSS-style)
/// Parses and expands grouped utility patterns:
/// - Bracket syntax: flex[col jc-center ai-center] → flex-col justify-center items-center
/// - Colon shorthand: bg:black → bg-black
/// - Reset utilities: reset:meyer → special reset handling
pub const GroupedSyntaxParser = struct {
    allocator: std.mem.Allocator,

    /// Expansion rules for common abbreviations
    /// Maps prefix -> (short -> expanded)
    const ExpansionRules = struct {
        // Flex shorthand expansions
        const flex = std.StaticStringMap([]const u8).initComptime(.{
            .{ "col", "flex-col" },
            .{ "row", "flex-row" },
            .{ "wrap", "flex-wrap" },
            .{ "nowrap", "flex-nowrap" },
            .{ "1", "flex-1" },
            .{ "auto", "flex-auto" },
            .{ "initial", "flex-initial" },
            .{ "none", "flex-none" },
            .{ "grow", "grow" },
            .{ "grow-0", "grow-0" },
            .{ "shrink", "shrink" },
            .{ "shrink-0", "shrink-0" },
            // Justify content shortcuts
            .{ "jc-start", "justify-start" },
            .{ "jc-end", "justify-end" },
            .{ "jc-center", "justify-center" },
            .{ "jc-between", "justify-between" },
            .{ "jc-around", "justify-around" },
            .{ "jc-evenly", "justify-evenly" },
            .{ "jc-stretch", "justify-stretch" },
            // Align items shortcuts
            .{ "ai-start", "items-start" },
            .{ "ai-end", "items-end" },
            .{ "ai-center", "items-center" },
            .{ "ai-baseline", "items-baseline" },
            .{ "ai-stretch", "items-stretch" },
            // Align content shortcuts
            .{ "ac-start", "content-start" },
            .{ "ac-end", "content-end" },
            .{ "ac-center", "content-center" },
            .{ "ac-between", "content-between" },
            .{ "ac-around", "content-around" },
            .{ "ac-evenly", "content-evenly" },
            .{ "ac-stretch", "content-stretch" },
            // Gap shortcuts
            .{ "gap", "gap" },
        });

        // Text shorthand expansions
        const text = std.StaticStringMap([]const u8).initComptime(.{
            // Font sizes
            .{ "xs", "text-xs" },
            .{ "sm", "text-sm" },
            .{ "base", "text-base" },
            .{ "lg", "text-lg" },
            .{ "xl", "text-xl" },
            .{ "2xl", "text-2xl" },
            .{ "3xl", "text-3xl" },
            .{ "4xl", "text-4xl" },
            .{ "5xl", "text-5xl" },
            // Font weights
            .{ "thin", "font-thin" },
            .{ "extralight", "font-extralight" },
            .{ "light", "font-light" },
            .{ "normal", "font-normal" },
            .{ "medium", "font-medium" },
            .{ "semibold", "font-semibold" },
            .{ "bold", "font-bold" },
            .{ "extrabold", "font-extrabold" },
            .{ "black", "font-black" },
            .{ "100", "font-thin" },
            .{ "200", "font-extralight" },
            .{ "300", "font-light" },
            .{ "400", "font-normal" },
            .{ "500", "font-medium" },
            .{ "600", "font-semibold" },
            .{ "700", "font-bold" },
            .{ "800", "font-extrabold" },
            .{ "900", "font-black" },
            // Text alignment
            .{ "left", "text-left" },
            .{ "center", "text-center" },
            .{ "right", "text-right" },
            .{ "justify", "text-justify" },
            // Font families
            .{ "sans", "font-sans" },
            .{ "serif", "font-serif" },
            .{ "mono", "font-mono" },
            .{ "arial", "font-[Arial]" },
            .{ "helvetica", "font-[Helvetica]" },
            .{ "georgia", "font-[Georgia]" },
            .{ "times", "font-['Times_New_Roman']" },
        });

        // Height shorthand expansions
        const h = std.StaticStringMap([]const u8).initComptime(.{
            .{ "full", "h-full" },
            .{ "screen", "h-screen" },
            .{ "svh", "h-svh" },
            .{ "lvh", "h-lvh" },
            .{ "dvh", "h-dvh" },
            .{ "min", "min-h" },
            .{ "max", "max-h" },
            .{ "fit", "h-fit" },
            .{ "auto", "h-auto" },
        });

        // Width shorthand expansions
        const w = std.StaticStringMap([]const u8).initComptime(.{
            .{ "full", "w-full" },
            .{ "screen", "w-screen" },
            .{ "svw", "w-svw" },
            .{ "lvw", "w-lvw" },
            .{ "dvw", "w-dvw" },
            .{ "min", "min-w" },
            .{ "max", "max-w" },
            .{ "fit", "w-fit" },
            .{ "auto", "w-auto" },
        });

        // Scroll shorthand expansions
        const scroll = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x", "overflow-x" },
            .{ "y", "overflow-y" },
            .{ "auto", "overflow-auto" },
            .{ "hidden", "overflow-hidden" },
            .{ "visible", "overflow-visible" },
            .{ "scroll", "overflow-scroll" },
            .{ "smooth", "scroll-smooth" },
            .{ "snap", "scroll-snap" },
        });

        // Background shorthand expansions (mostly pass through to bg-)
        const bg = std.StaticStringMap([]const u8).initComptime(.{
            .{ "fixed", "bg-fixed" },
            .{ "local", "bg-local" },
            .{ "scroll", "bg-scroll" },
            .{ "clip-border", "bg-clip-border" },
            .{ "clip-padding", "bg-clip-padding" },
            .{ "clip-content", "bg-clip-content" },
            .{ "clip-text", "bg-clip-text" },
            .{ "origin-border", "bg-origin-border" },
            .{ "origin-padding", "bg-origin-padding" },
            .{ "origin-content", "bg-origin-content" },
            .{ "repeat", "bg-repeat" },
            .{ "no-repeat", "bg-no-repeat" },
            .{ "repeat-x", "bg-repeat-x" },
            .{ "repeat-y", "bg-repeat-y" },
            .{ "repeat-round", "bg-repeat-round" },
            .{ "repeat-space", "bg-repeat-space" },
            .{ "cover", "bg-cover" },
            .{ "contain", "bg-contain" },
            .{ "auto", "bg-auto" },
            .{ "center", "bg-center" },
            .{ "top", "bg-top" },
            .{ "bottom", "bg-bottom" },
            .{ "left", "bg-left" },
            .{ "right", "bg-right" },
        });

        // Border shorthand expansions
        const border = std.StaticStringMap([]const u8).initComptime(.{
            .{ "solid", "border-solid" },
            .{ "dashed", "border-dashed" },
            .{ "dotted", "border-dotted" },
            .{ "double", "border-double" },
            .{ "hidden", "border-hidden" },
            .{ "none", "border-none" },
            .{ "collapse", "border-collapse" },
            .{ "separate", "border-separate" },
        });

        // Grid shorthand expansions
        const grid = std.StaticStringMap([]const u8).initComptime(.{
            .{ "cols", "grid-cols" },
            .{ "rows", "grid-rows" },
            .{ "flow-row", "grid-flow-row" },
            .{ "flow-col", "grid-flow-col" },
            .{ "flow-dense", "grid-flow-dense" },
            .{ "flow-row-dense", "grid-flow-row-dense" },
            .{ "flow-col-dense", "grid-flow-col-dense" },
        });

        // Padding shorthand expansions
        const p = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x", "px" },
            .{ "y", "py" },
            .{ "t", "pt" },
            .{ "b", "pb" },
            .{ "l", "pl" },
            .{ "r", "pr" },
            .{ "s", "ps" },
            .{ "e", "pe" },
        });

        // Margin shorthand expansions
        const m = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x", "mx" },
            .{ "y", "my" },
            .{ "t", "mt" },
            .{ "b", "mb" },
            .{ "l", "ml" },
            .{ "r", "mr" },
            .{ "s", "ms" },
            .{ "e", "me" },
            .{ "auto", "m-auto" },
        });

        // Rounded shorthand expansions
        const rounded = std.StaticStringMap([]const u8).initComptime(.{
            .{ "t", "rounded-t" },
            .{ "b", "rounded-b" },
            .{ "l", "rounded-l" },
            .{ "r", "rounded-r" },
            .{ "tl", "rounded-tl" },
            .{ "tr", "rounded-tr" },
            .{ "bl", "rounded-bl" },
            .{ "br", "rounded-br" },
            .{ "s", "rounded-s" },
            .{ "e", "rounded-e" },
            .{ "ss", "rounded-ss" },
            .{ "se", "rounded-se" },
            .{ "es", "rounded-es" },
            .{ "ee", "rounded-ee" },
            .{ "none", "rounded-none" },
            .{ "sm", "rounded-sm" },
            .{ "md", "rounded-md" },
            .{ "lg", "rounded-lg" },
            .{ "xl", "rounded-xl" },
            .{ "2xl", "rounded-2xl" },
            .{ "3xl", "rounded-3xl" },
            .{ "full", "rounded-full" },
        });

        // Space (children spacing) shorthand expansions
        const space = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x", "space-x" },
            .{ "y", "space-y" },
        });

        // Gap shorthand expansions
        const gap = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x", "gap-x" },
            .{ "y", "gap-y" },
        });

        // Inset (positioning) shorthand expansions
        const inset = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x", "inset-x" },
            .{ "y", "inset-y" },
            .{ "t", "top" },
            .{ "b", "bottom" },
            .{ "l", "left" },
            .{ "r", "right" },
            .{ "0", "inset-0" },
            .{ "auto", "inset-auto" },
        });

        // Ring shorthand expansions
        const ring = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "ring-0" },
            .{ "1", "ring-1" },
            .{ "2", "ring-2" },
            .{ "4", "ring-4" },
            .{ "8", "ring-8" },
            .{ "inset", "ring-inset" },
        });

        // Transition shorthand expansions
        const transition = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "transition-none" },
            .{ "all", "transition-all" },
            .{ "colors", "transition-colors" },
            .{ "opacity", "transition-opacity" },
            .{ "shadow", "transition-shadow" },
            .{ "transform", "transition-transform" },
            // Durations
            .{ "75", "duration-75" },
            .{ "100", "duration-100" },
            .{ "150", "duration-150" },
            .{ "200", "duration-200" },
            .{ "300", "duration-300" },
            .{ "500", "duration-500" },
            .{ "700", "duration-700" },
            .{ "1000", "duration-1000" },
            // Timing functions
            .{ "ease-linear", "ease-linear" },
            .{ "ease-in", "ease-in" },
            .{ "ease-out", "ease-out" },
            .{ "ease-in-out", "ease-in-out" },
            // Delays
            .{ "delay-75", "delay-75" },
            .{ "delay-100", "delay-100" },
            .{ "delay-150", "delay-150" },
            .{ "delay-200", "delay-200" },
            .{ "delay-300", "delay-300" },
            .{ "delay-500", "delay-500" },
        });

        // Animation shorthand expansions
        const animate = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "animate-none" },
            .{ "spin", "animate-spin" },
            .{ "ping", "animate-ping" },
            .{ "pulse", "animate-pulse" },
            .{ "bounce", "animate-bounce" },
        });

        // Font shorthand expansions
        const font = std.StaticStringMap([]const u8).initComptime(.{
            .{ "thin", "font-thin" },
            .{ "extralight", "font-extralight" },
            .{ "light", "font-light" },
            .{ "normal", "font-normal" },
            .{ "medium", "font-medium" },
            .{ "semibold", "font-semibold" },
            .{ "bold", "font-bold" },
            .{ "extrabold", "font-extrabold" },
            .{ "black", "font-black" },
            .{ "sans", "font-sans" },
            .{ "serif", "font-serif" },
            .{ "mono", "font-mono" },
            // Numeric weights
            .{ "100", "font-thin" },
            .{ "200", "font-extralight" },
            .{ "300", "font-light" },
            .{ "400", "font-normal" },
            .{ "500", "font-medium" },
            .{ "600", "font-semibold" },
            .{ "700", "font-bold" },
            .{ "800", "font-extrabold" },
            .{ "900", "font-black" },
        });

        // Opacity shorthand
        const opacity = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "opacity-0" },
            .{ "5", "opacity-5" },
            .{ "10", "opacity-10" },
            .{ "20", "opacity-20" },
            .{ "25", "opacity-25" },
            .{ "30", "opacity-30" },
            .{ "40", "opacity-40" },
            .{ "50", "opacity-50" },
            .{ "60", "opacity-60" },
            .{ "70", "opacity-70" },
            .{ "75", "opacity-75" },
            .{ "80", "opacity-80" },
            .{ "90", "opacity-90" },
            .{ "95", "opacity-95" },
            .{ "100", "opacity-100" },
        });

        // Z-index shorthand
        const z = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "z-0" },
            .{ "10", "z-10" },
            .{ "20", "z-20" },
            .{ "30", "z-30" },
            .{ "40", "z-40" },
            .{ "50", "z-50" },
            .{ "auto", "z-auto" },
        });

        // Translate shorthand
        const translate = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x-0", "translate-x-0" },
            .{ "y-0", "translate-y-0" },
            .{ "x-full", "translate-x-full" },
            .{ "y-full", "translate-y-full" },
            .{ "x-1/2", "translate-x-1/2" },
            .{ "y-1/2", "translate-y-1/2" },
        });

        // Rotate shorthand
        const rotate = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "rotate-0" },
            .{ "1", "rotate-1" },
            .{ "2", "rotate-2" },
            .{ "3", "rotate-3" },
            .{ "6", "rotate-6" },
            .{ "12", "rotate-12" },
            .{ "45", "rotate-45" },
            .{ "90", "rotate-90" },
            .{ "180", "rotate-180" },
        });

        // Scale shorthand
        const scale = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "scale-0" },
            .{ "50", "scale-50" },
            .{ "75", "scale-75" },
            .{ "90", "scale-90" },
            .{ "95", "scale-95" },
            .{ "100", "scale-100" },
            .{ "105", "scale-105" },
            .{ "110", "scale-110" },
            .{ "125", "scale-125" },
            .{ "150", "scale-150" },
        });

        // Cursor shorthand
        const cursor = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "cursor-auto" },
            .{ "default", "cursor-default" },
            .{ "pointer", "cursor-pointer" },
            .{ "wait", "cursor-wait" },
            .{ "text", "cursor-text" },
            .{ "move", "cursor-move" },
            .{ "help", "cursor-help" },
            .{ "not-allowed", "cursor-not-allowed" },
            .{ "none", "cursor-none" },
            .{ "grab", "cursor-grab" },
            .{ "grabbing", "cursor-grabbing" },
        });

        // Select shorthand
        const select = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "select-none" },
            .{ "text", "select-text" },
            .{ "all", "select-all" },
            .{ "auto", "select-auto" },
        });

        // Overflow shorthand
        const overflow = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "overflow-auto" },
            .{ "hidden", "overflow-hidden" },
            .{ "clip", "overflow-clip" },
            .{ "visible", "overflow-visible" },
            .{ "scroll", "overflow-scroll" },
        });

        // Aspect shorthand
        const aspect = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "aspect-auto" },
            .{ "square", "aspect-square" },
            .{ "video", "aspect-video" },
        });

        // Object shorthand
        const object = std.StaticStringMap([]const u8).initComptime(.{
            .{ "contain", "object-contain" },
            .{ "cover", "object-cover" },
            .{ "fill", "object-fill" },
            .{ "none", "object-none" },
            .{ "scale-down", "object-scale-down" },
            .{ "bottom", "object-bottom" },
            .{ "center", "object-center" },
            .{ "left", "object-left" },
            .{ "left-bottom", "object-left-bottom" },
            .{ "left-top", "object-left-top" },
            .{ "right", "object-right" },
            .{ "right-bottom", "object-right-bottom" },
            .{ "right-top", "object-right-top" },
            .{ "top", "object-top" },
        });

        // Items shorthand (align-items)
        const items = std.StaticStringMap([]const u8).initComptime(.{
            .{ "start", "items-start" },
            .{ "end", "items-end" },
            .{ "center", "items-center" },
            .{ "baseline", "items-baseline" },
            .{ "stretch", "items-stretch" },
        });

        // Justify shorthand (justify-content)
        const justify = std.StaticStringMap([]const u8).initComptime(.{
            .{ "start", "justify-start" },
            .{ "end", "justify-end" },
            .{ "center", "justify-center" },
            .{ "between", "justify-between" },
            .{ "around", "justify-around" },
            .{ "evenly", "justify-evenly" },
            .{ "stretch", "justify-stretch" },
        });

        // Content shorthand (align-content)
        const content = std.StaticStringMap([]const u8).initComptime(.{
            .{ "start", "content-start" },
            .{ "end", "content-end" },
            .{ "center", "content-center" },
            .{ "between", "content-between" },
            .{ "around", "content-around" },
            .{ "evenly", "content-evenly" },
            .{ "stretch", "content-stretch" },
            .{ "none", "content-none" },
        });

        // Self shorthand (align-self)
        const self = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "self-auto" },
            .{ "start", "self-start" },
            .{ "end", "self-end" },
            .{ "center", "self-center" },
            .{ "stretch", "self-stretch" },
            .{ "baseline", "self-baseline" },
        });

        // Place shorthand
        const place = std.StaticStringMap([]const u8).initComptime(.{
            .{ "content-start", "place-content-start" },
            .{ "content-end", "place-content-end" },
            .{ "content-center", "place-content-center" },
            .{ "content-between", "place-content-between" },
            .{ "content-around", "place-content-around" },
            .{ "content-evenly", "place-content-evenly" },
            .{ "content-stretch", "place-content-stretch" },
            .{ "items-start", "place-items-start" },
            .{ "items-end", "place-items-end" },
            .{ "items-center", "place-items-center" },
            .{ "items-stretch", "place-items-stretch" },
            .{ "self-auto", "place-self-auto" },
            .{ "self-start", "place-self-start" },
            .{ "self-end", "place-self-end" },
            .{ "self-center", "place-self-center" },
            .{ "self-stretch", "place-self-stretch" },
        });

        // Order shorthand
        const order = std.StaticStringMap([]const u8).initComptime(.{
            .{ "first", "order-first" },
            .{ "last", "order-last" },
            .{ "none", "order-none" },
            .{ "1", "order-1" },
            .{ "2", "order-2" },
            .{ "3", "order-3" },
            .{ "4", "order-4" },
            .{ "5", "order-5" },
            .{ "6", "order-6" },
            .{ "7", "order-7" },
            .{ "8", "order-8" },
            .{ "9", "order-9" },
            .{ "10", "order-10" },
            .{ "11", "order-11" },
            .{ "12", "order-12" },
        });

        // Tracking shorthand (letter-spacing)
        const tracking = std.StaticStringMap([]const u8).initComptime(.{
            .{ "tighter", "tracking-tighter" },
            .{ "tight", "tracking-tight" },
            .{ "normal", "tracking-normal" },
            .{ "wide", "tracking-wide" },
            .{ "wider", "tracking-wider" },
            .{ "widest", "tracking-widest" },
        });

        // Leading shorthand (line-height)
        const leading = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "leading-none" },
            .{ "tight", "leading-tight" },
            .{ "snug", "leading-snug" },
            .{ "normal", "leading-normal" },
            .{ "relaxed", "leading-relaxed" },
            .{ "loose", "leading-loose" },
            .{ "3", "leading-3" },
            .{ "4", "leading-4" },
            .{ "5", "leading-5" },
            .{ "6", "leading-6" },
            .{ "7", "leading-7" },
            .{ "8", "leading-8" },
            .{ "9", "leading-9" },
            .{ "10", "leading-10" },
        });

        // List shorthand
        const list = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "list-none" },
            .{ "disc", "list-disc" },
            .{ "decimal", "list-decimal" },
            .{ "inside", "list-inside" },
            .{ "outside", "list-outside" },
        });

        // Decoration shorthand
        const decoration = std.StaticStringMap([]const u8).initComptime(.{
            .{ "solid", "decoration-solid" },
            .{ "double", "decoration-double" },
            .{ "dotted", "decoration-dotted" },
            .{ "dashed", "decoration-dashed" },
            .{ "wavy", "decoration-wavy" },
            .{ "auto", "decoration-auto" },
            .{ "from-font", "decoration-from-font" },
            .{ "0", "decoration-0" },
            .{ "1", "decoration-1" },
            .{ "2", "decoration-2" },
            .{ "4", "decoration-4" },
            .{ "8", "decoration-8" },
        });

        // Blur shorthand
        const blur = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "blur-none" },
            .{ "sm", "blur-sm" },
            .{ "md", "blur-md" },
            .{ "lg", "blur-lg" },
            .{ "xl", "blur-xl" },
            .{ "2xl", "blur-2xl" },
            .{ "3xl", "blur-3xl" },
        });

        // Brightness shorthand
        const brightness = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "brightness-0" },
            .{ "50", "brightness-50" },
            .{ "75", "brightness-75" },
            .{ "90", "brightness-90" },
            .{ "95", "brightness-95" },
            .{ "100", "brightness-100" },
            .{ "105", "brightness-105" },
            .{ "110", "brightness-110" },
            .{ "125", "brightness-125" },
            .{ "150", "brightness-150" },
            .{ "200", "brightness-200" },
        });

        // Contrast shorthand
        const contrast = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "contrast-0" },
            .{ "50", "contrast-50" },
            .{ "75", "contrast-75" },
            .{ "100", "contrast-100" },
            .{ "125", "contrast-125" },
            .{ "150", "contrast-150" },
            .{ "200", "contrast-200" },
        });

        // Saturate shorthand
        const saturate = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "saturate-0" },
            .{ "50", "saturate-50" },
            .{ "100", "saturate-100" },
            .{ "150", "saturate-150" },
            .{ "200", "saturate-200" },
        });

        // Grayscale shorthand
        const grayscale = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "grayscale-0" },
            .{ "100", "grayscale" },
        });

        // Sepia shorthand
        const sepia = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "sepia-0" },
            .{ "100", "sepia" },
        });

        // Invert shorthand
        const invert = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "invert-0" },
            .{ "100", "invert" },
        });

        // Backdrop shorthand
        const backdrop = std.StaticStringMap([]const u8).initComptime(.{
            .{ "blur-none", "backdrop-blur-none" },
            .{ "blur-sm", "backdrop-blur-sm" },
            .{ "blur", "backdrop-blur" },
            .{ "blur-md", "backdrop-blur-md" },
            .{ "blur-lg", "backdrop-blur-lg" },
            .{ "blur-xl", "backdrop-blur-xl" },
            .{ "blur-2xl", "backdrop-blur-2xl" },
            .{ "blur-3xl", "backdrop-blur-3xl" },
        });

        // Origin shorthand (transform-origin)
        const origin = std.StaticStringMap([]const u8).initComptime(.{
            .{ "center", "origin-center" },
            .{ "top", "origin-top" },
            .{ "top-right", "origin-top-right" },
            .{ "right", "origin-right" },
            .{ "bottom-right", "origin-bottom-right" },
            .{ "bottom", "origin-bottom" },
            .{ "bottom-left", "origin-bottom-left" },
            .{ "left", "origin-left" },
            .{ "top-left", "origin-top-left" },
        });

        // Duration shorthand
        const duration = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "duration-0" },
            .{ "75", "duration-75" },
            .{ "100", "duration-100" },
            .{ "150", "duration-150" },
            .{ "200", "duration-200" },
            .{ "300", "duration-300" },
            .{ "500", "duration-500" },
            .{ "700", "duration-700" },
            .{ "1000", "duration-1000" },
        });

        // Delay shorthand
        const delay = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "delay-0" },
            .{ "75", "delay-75" },
            .{ "100", "delay-100" },
            .{ "150", "delay-150" },
            .{ "200", "delay-200" },
            .{ "300", "delay-300" },
            .{ "500", "delay-500" },
            .{ "700", "delay-700" },
            .{ "1000", "delay-1000" },
        });

        // Ease shorthand
        const ease = std.StaticStringMap([]const u8).initComptime(.{
            .{ "linear", "ease-linear" },
            .{ "in", "ease-in" },
            .{ "out", "ease-out" },
            .{ "in-out", "ease-in-out" },
        });

        // Outline shorthand
        const outline = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "outline-none" },
            .{ "0", "outline-0" },
            .{ "1", "outline-1" },
            .{ "2", "outline-2" },
            .{ "4", "outline-4" },
            .{ "8", "outline-8" },
        });

        // Shadow shorthand
        const shadow = std.StaticStringMap([]const u8).initComptime(.{
            .{ "sm", "shadow-sm" },
            .{ "md", "shadow-md" },
            .{ "lg", "shadow-lg" },
            .{ "xl", "shadow-xl" },
            .{ "2xl", "shadow-2xl" },
            .{ "inner", "shadow-inner" },
            .{ "none", "shadow-none" },
        });

        // Pointer shorthand (pointer-events)
        const pointer = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "pointer-events-none" },
            .{ "auto", "pointer-events-auto" },
        });

        // Resize shorthand
        const resize = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "resize-none" },
            .{ "y", "resize-y" },
            .{ "x", "resize-x" },
            .{ "both", "resize" },
        });

        // Will-change shorthand
        const will = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "will-change-auto" },
            .{ "scroll", "will-change-scroll" },
            .{ "contents", "will-change-contents" },
            .{ "transform", "will-change-transform" },
        });

        // Snap shorthand
        const snap = std.StaticStringMap([]const u8).initComptime(.{
            .{ "start", "snap-start" },
            .{ "end", "snap-end" },
            .{ "center", "snap-center" },
            .{ "align-none", "snap-align-none" },
            .{ "normal", "snap-normal" },
            .{ "always", "snap-always" },
            .{ "none", "snap-none" },
            .{ "x", "snap-x" },
            .{ "y", "snap-y" },
            .{ "both", "snap-both" },
            .{ "mandatory", "snap-mandatory" },
            .{ "proximity", "snap-proximity" },
        });

        // Touch shorthand
        const touch = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "touch-auto" },
            .{ "none", "touch-none" },
            .{ "pan-x", "touch-pan-x" },
            .{ "pan-left", "touch-pan-left" },
            .{ "pan-right", "touch-pan-right" },
            .{ "pan-y", "touch-pan-y" },
            .{ "pan-up", "touch-pan-up" },
            .{ "pan-down", "touch-pan-down" },
            .{ "pinch-zoom", "touch-pinch-zoom" },
            .{ "manipulation", "touch-manipulation" },
        });

        // Fill shorthand (SVG)
        const fill = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "fill-none" },
            .{ "inherit", "fill-inherit" },
            .{ "current", "fill-current" },
            .{ "transparent", "fill-transparent" },
        });

        // Stroke shorthand (SVG)
        const stroke = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "stroke-none" },
            .{ "inherit", "stroke-inherit" },
            .{ "current", "stroke-current" },
            .{ "transparent", "stroke-transparent" },
            .{ "0", "stroke-0" },
            .{ "1", "stroke-1" },
            .{ "2", "stroke-2" },
        });

        // Columns shorthand
        const columns = std.StaticStringMap([]const u8).initComptime(.{
            .{ "1", "columns-1" },
            .{ "2", "columns-2" },
            .{ "3", "columns-3" },
            .{ "4", "columns-4" },
            .{ "5", "columns-5" },
            .{ "6", "columns-6" },
            .{ "7", "columns-7" },
            .{ "8", "columns-8" },
            .{ "9", "columns-9" },
            .{ "10", "columns-10" },
            .{ "11", "columns-11" },
            .{ "12", "columns-12" },
            .{ "auto", "columns-auto" },
            .{ "3xs", "columns-3xs" },
            .{ "2xs", "columns-2xs" },
            .{ "xs", "columns-xs" },
            .{ "sm", "columns-sm" },
            .{ "md", "columns-md" },
            .{ "lg", "columns-lg" },
            .{ "xl", "columns-xl" },
            .{ "2xl", "columns-2xl" },
            .{ "3xl", "columns-3xl" },
            .{ "4xl", "columns-4xl" },
            .{ "5xl", "columns-5xl" },
            .{ "6xl", "columns-6xl" },
            .{ "7xl", "columns-7xl" },
        });

        // Break shorthand
        const @"break" = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "break-auto" },
            .{ "avoid", "break-avoid" },
            .{ "all", "break-all" },
            .{ "avoid-page", "break-avoid-page" },
            .{ "page", "break-page" },
            .{ "left", "break-left" },
            .{ "right", "break-right" },
            .{ "column", "break-column" },
            .{ "before-auto", "break-before-auto" },
            .{ "before-avoid", "break-before-avoid" },
            .{ "before-all", "break-before-all" },
            .{ "before-page", "break-before-page" },
            .{ "before-column", "break-before-column" },
            .{ "after-auto", "break-after-auto" },
            .{ "after-avoid", "break-after-avoid" },
            .{ "after-all", "break-after-all" },
            .{ "after-page", "break-after-page" },
            .{ "after-column", "break-after-column" },
            .{ "inside-auto", "break-inside-auto" },
            .{ "inside-avoid", "break-inside-avoid" },
            .{ "inside-avoid-page", "break-inside-avoid-page" },
            .{ "inside-avoid-column", "break-inside-avoid-column" },
            .{ "words", "break-words" },
            .{ "normal", "break-normal" },
            .{ "keep", "break-keep" },
        });

        // Drop shadow shorthand
        const drop_shadow = std.StaticStringMap([]const u8).initComptime(.{
            .{ "sm", "drop-shadow-sm" },
            .{ "md", "drop-shadow-md" },
            .{ "lg", "drop-shadow-lg" },
            .{ "xl", "drop-shadow-xl" },
            .{ "2xl", "drop-shadow-2xl" },
            .{ "none", "drop-shadow-none" },
        });

        // Skew shorthand
        const skew = std.StaticStringMap([]const u8).initComptime(.{
            .{ "x-0", "skew-x-0" },
            .{ "y-0", "skew-y-0" },
            .{ "x-1", "skew-x-1" },
            .{ "y-1", "skew-y-1" },
            .{ "x-2", "skew-x-2" },
            .{ "y-2", "skew-y-2" },
            .{ "x-3", "skew-x-3" },
            .{ "y-3", "skew-y-3" },
            .{ "x-6", "skew-x-6" },
            .{ "y-6", "skew-y-6" },
            .{ "x-12", "skew-x-12" },
            .{ "y-12", "skew-y-12" },
        });

        // Accent shorthand
        const accent = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "accent-auto" },
            .{ "inherit", "accent-inherit" },
            .{ "current", "accent-current" },
            .{ "transparent", "accent-transparent" },
        });

        // Caret shorthand
        const caret = std.StaticStringMap([]const u8).initComptime(.{
            .{ "inherit", "caret-inherit" },
            .{ "current", "caret-current" },
            .{ "transparent", "caret-transparent" },
        });

        // Appearance shorthand
        const appearance = std.StaticStringMap([]const u8).initComptime(.{
            .{ "none", "appearance-none" },
            .{ "auto", "appearance-auto" },
        });

        // Overscroll shorthand
        const overscroll = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "overscroll-auto" },
            .{ "contain", "overscroll-contain" },
            .{ "none", "overscroll-none" },
            .{ "y-auto", "overscroll-y-auto" },
            .{ "y-contain", "overscroll-y-contain" },
            .{ "y-none", "overscroll-y-none" },
            .{ "x-auto", "overscroll-x-auto" },
            .{ "x-contain", "overscroll-x-contain" },
            .{ "x-none", "overscroll-x-none" },
        });

        // Col shorthand (grid column)
        const col = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "col-auto" },
            .{ "span-1", "col-span-1" },
            .{ "span-2", "col-span-2" },
            .{ "span-3", "col-span-3" },
            .{ "span-4", "col-span-4" },
            .{ "span-5", "col-span-5" },
            .{ "span-6", "col-span-6" },
            .{ "span-7", "col-span-7" },
            .{ "span-8", "col-span-8" },
            .{ "span-9", "col-span-9" },
            .{ "span-10", "col-span-10" },
            .{ "span-11", "col-span-11" },
            .{ "span-12", "col-span-12" },
            .{ "span-full", "col-span-full" },
            .{ "start-1", "col-start-1" },
            .{ "start-2", "col-start-2" },
            .{ "start-3", "col-start-3" },
            .{ "start-4", "col-start-4" },
            .{ "start-5", "col-start-5" },
            .{ "start-6", "col-start-6" },
            .{ "start-7", "col-start-7" },
            .{ "start-8", "col-start-8" },
            .{ "start-9", "col-start-9" },
            .{ "start-10", "col-start-10" },
            .{ "start-11", "col-start-11" },
            .{ "start-12", "col-start-12" },
            .{ "start-13", "col-start-13" },
            .{ "start-auto", "col-start-auto" },
            .{ "end-1", "col-end-1" },
            .{ "end-2", "col-end-2" },
            .{ "end-3", "col-end-3" },
            .{ "end-4", "col-end-4" },
            .{ "end-5", "col-end-5" },
            .{ "end-6", "col-end-6" },
            .{ "end-7", "col-end-7" },
            .{ "end-8", "col-end-8" },
            .{ "end-9", "col-end-9" },
            .{ "end-10", "col-end-10" },
            .{ "end-11", "col-end-11" },
            .{ "end-12", "col-end-12" },
            .{ "end-13", "col-end-13" },
            .{ "end-auto", "col-end-auto" },
        });

        // Row shorthand (grid row)
        const row = std.StaticStringMap([]const u8).initComptime(.{
            .{ "auto", "row-auto" },
            .{ "span-1", "row-span-1" },
            .{ "span-2", "row-span-2" },
            .{ "span-3", "row-span-3" },
            .{ "span-4", "row-span-4" },
            .{ "span-5", "row-span-5" },
            .{ "span-6", "row-span-6" },
            .{ "span-full", "row-span-full" },
            .{ "start-1", "row-start-1" },
            .{ "start-2", "row-start-2" },
            .{ "start-3", "row-start-3" },
            .{ "start-4", "row-start-4" },
            .{ "start-5", "row-start-5" },
            .{ "start-6", "row-start-6" },
            .{ "start-7", "row-start-7" },
            .{ "start-auto", "row-start-auto" },
            .{ "end-1", "row-end-1" },
            .{ "end-2", "row-end-2" },
            .{ "end-3", "row-end-3" },
            .{ "end-4", "row-end-4" },
            .{ "end-5", "row-end-5" },
            .{ "end-6", "row-end-6" },
            .{ "end-7", "row-end-7" },
            .{ "end-auto", "row-end-auto" },
        });

        // Top shorthand
        const top = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "top-0" },
            .{ "px", "top-px" },
            .{ "auto", "top-auto" },
            .{ "full", "top-full" },
            .{ "1/2", "top-1/2" },
            .{ "1/3", "top-1/3" },
            .{ "2/3", "top-2/3" },
            .{ "1/4", "top-1/4" },
            .{ "3/4", "top-3/4" },
        });

        // Right shorthand
        const right = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "right-0" },
            .{ "px", "right-px" },
            .{ "auto", "right-auto" },
            .{ "full", "right-full" },
            .{ "1/2", "right-1/2" },
            .{ "1/3", "right-1/3" },
            .{ "2/3", "right-2/3" },
            .{ "1/4", "right-1/4" },
            .{ "3/4", "right-3/4" },
        });

        // Bottom shorthand
        const bottom = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "bottom-0" },
            .{ "px", "bottom-px" },
            .{ "auto", "bottom-auto" },
            .{ "full", "bottom-full" },
            .{ "1/2", "bottom-1/2" },
            .{ "1/3", "bottom-1/3" },
            .{ "2/3", "bottom-2/3" },
            .{ "1/4", "bottom-1/4" },
            .{ "3/4", "bottom-3/4" },
        });

        // Left shorthand
        const left = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "left-0" },
            .{ "px", "left-px" },
            .{ "auto", "left-auto" },
            .{ "full", "left-full" },
            .{ "1/2", "left-1/2" },
            .{ "1/3", "left-1/3" },
            .{ "2/3", "left-2/3" },
            .{ "1/4", "left-1/4" },
            .{ "3/4", "left-3/4" },
        });

        // Directional padding prefixes (standalone)
        const px = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "px-0" },
            .{ "1", "px-1" },
            .{ "2", "px-2" },
            .{ "3", "px-3" },
            .{ "4", "px-4" },
            .{ "5", "px-5" },
            .{ "6", "px-6" },
            .{ "8", "px-8" },
        });

        const py = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "py-0" },
            .{ "1", "py-1" },
            .{ "2", "py-2" },
            .{ "3", "py-3" },
            .{ "4", "py-4" },
            .{ "5", "py-5" },
            .{ "6", "py-6" },
            .{ "8", "py-8" },
        });

        const pt = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "pt-0" },
            .{ "1", "pt-1" },
            .{ "2", "pt-2" },
            .{ "4", "pt-4" },
            .{ "8", "pt-8" },
        });

        const pr = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "pr-0" },
            .{ "1", "pr-1" },
            .{ "2", "pr-2" },
            .{ "4", "pr-4" },
            .{ "8", "pr-8" },
        });

        const pb = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "pb-0" },
            .{ "1", "pb-1" },
            .{ "2", "pb-2" },
            .{ "4", "pb-4" },
            .{ "8", "pb-8" },
        });

        const pl = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "pl-0" },
            .{ "1", "pl-1" },
            .{ "2", "pl-2" },
            .{ "4", "pl-4" },
            .{ "8", "pl-8" },
        });

        // Directional margin prefixes (standalone)
        const mx = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "mx-0" },
            .{ "auto", "mx-auto" },
            .{ "1", "mx-1" },
            .{ "2", "mx-2" },
            .{ "4", "mx-4" },
            .{ "8", "mx-8" },
        });

        const my = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "my-0" },
            .{ "auto", "my-auto" },
            .{ "1", "my-1" },
            .{ "2", "my-2" },
            .{ "4", "my-4" },
            .{ "8", "my-8" },
        });

        const mt = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "mt-0" },
            .{ "auto", "mt-auto" },
            .{ "1", "mt-1" },
            .{ "2", "mt-2" },
            .{ "4", "mt-4" },
            .{ "8", "mt-8" },
        });

        const mr = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "mr-0" },
            .{ "auto", "mr-auto" },
            .{ "1", "mr-1" },
            .{ "2", "mr-2" },
            .{ "4", "mr-4" },
            .{ "8", "mr-8" },
        });

        const mb = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "mb-0" },
            .{ "auto", "mb-auto" },
            .{ "1", "mb-1" },
            .{ "2", "mb-2" },
            .{ "4", "mb-4" },
            .{ "8", "mb-8" },
        });

        const ml = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "ml-0" },
            .{ "auto", "ml-auto" },
            .{ "1", "ml-1" },
            .{ "2", "ml-2" },
            .{ "4", "ml-4" },
            .{ "8", "ml-8" },
        });

        // Underline utilities
        const underline = std.StaticStringMap([]const u8).initComptime(.{
            .{ "offset", "underline-offset" },
            .{ "offset-auto", "underline-offset-auto" },
            .{ "offset-0", "underline-offset-0" },
            .{ "offset-1", "underline-offset-1" },
            .{ "offset-2", "underline-offset-2" },
            .{ "offset-4", "underline-offset-4" },
            .{ "offset-8", "underline-offset-8" },
        });

        // Scroll margin utilities
        const scroll_m = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "scroll-m-0" },
            .{ "1", "scroll-m-1" },
            .{ "2", "scroll-m-2" },
            .{ "4", "scroll-m-4" },
            .{ "8", "scroll-m-8" },
        });

        // Scroll padding utilities
        const scroll_p = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "scroll-p-0" },
            .{ "1", "scroll-p-1" },
            .{ "2", "scroll-p-2" },
            .{ "4", "scroll-p-4" },
            .{ "8", "scroll-p-8" },
        });

        // Screen reader utilities
        const sr = std.StaticStringMap([]const u8).initComptime(.{
            .{ "only", "sr-only" },
            .{ "not", "not-sr-only" },
        });

        // Hue rotate
        const hue_rotate = std.StaticStringMap([]const u8).initComptime(.{
            .{ "0", "hue-rotate-0" },
            .{ "15", "hue-rotate-15" },
            .{ "30", "hue-rotate-30" },
            .{ "60", "hue-rotate-60" },
            .{ "90", "hue-rotate-90" },
            .{ "180", "hue-rotate-180" },
        });
    };

    pub fn init(allocator: std.mem.Allocator) GroupedSyntaxParser {
        return .{ .allocator = allocator };
    }

    /// Known responsive and state variant prefixes
    const variant_prefixes = [_][]const u8{
        // Responsive
        "sm",            "md",            "lg",            "xl",           "2xl",
        // State
        "hover",         "focus",         "active",        "visited",      "disabled",
        "enabled",       "checked",       "indeterminate", "default",      "required",
        "valid",         "invalid",       "in-range",      "out-of-range", "placeholder-shown",
        "autofill",      "read-only",
        // First/last/odd/even
            "first",         "last",         "odd",
        "even",          "only",          "first-of-type", "last-of-type", "empty",
        // Focus
        "focus-within",  "focus-visible",
        // Dark mode
        "dark",
        // Print
                 "print",
        // Motion
               "motion-safe",
        "motion-reduce",
        // Contrast
        "contrast-more", "contrast-less",
        // Content
        "before",       "after",
        "selection",     "marker",        "file",
        // RTL/LTR
                 "rtl",          "ltr",
        // Orientation
        "portrait",      "landscape",
        // Group/peer
            "group-hover",   "group-focus",  "peer-hover",
        "peer-focus",
        // Container queries
           "@sm",           "@md",           "@lg",          "@xl",
        "@2xl",
    };

    /// Check if a prefix is a known variant
    fn isVariantPrefix(prefix: []const u8) bool {
        for (variant_prefixes) |vp| {
            if (std.mem.eql(u8, prefix, vp)) return true;
        }
        return false;
    }

    /// Parse a grouped syntax class and expand into standard utility classes
    /// Returns null if not a grouped syntax pattern
    pub fn parseAndExpand(self: *GroupedSyntaxParser, class_str: []const u8) !?[][]const u8 {
        const trimmed = string_utils.trim(class_str);
        if (trimmed.len == 0) return null;

        // Check for responsive/variant prefix: md:flex[col], hover:bg[blue-500]
        // This is different from colon shorthand - the prefix is followed by another grouped pattern
        if (simd.simdIndexOfScalar(trimmed, ':')) |first_colon| {
            const potential_variant = trimmed[0..first_colon];
            const rest = trimmed[first_colon + 1 ..];

            // If the prefix is a known variant and the rest contains brackets, expand with variant
            if (isVariantPrefix(potential_variant) and simd.simdIndexOfScalar(rest, '[') != null) {
                // Recursively expand the rest, then prepend variant to each result
                if (try self.parseAndExpand(rest)) |expanded| {
                    var results: std.ArrayList([]const u8) = .empty;
                    errdefer {
                        for (results.items) |item| self.allocator.free(item);
                        results.deinit(self.allocator);
                    }

                    for (expanded) |exp_class| {
                        defer self.allocator.free(exp_class);
                        const with_variant = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ potential_variant, exp_class });
                        try results.append(self.allocator, with_variant);
                    }
                    self.allocator.free(expanded);

                    return try results.toOwnedSlice(self.allocator);
                }
            }
        }

        // Check for bracket syntax: prefix[values]
        if (simd.simdIndexOfScalar(trimmed, '[')) |bracket_start| {
            if (bracket_start > 0) {
                return try self.expandBracketSyntax(trimmed, bracket_start);
            }
        }

        // Check for colon shorthand: prefix:value (but not variants like hover:)
        // Colon shorthand is only for simple prefix:value patterns, not prefix:value:more
        if (simd.simdIndexOfScalar(trimmed, ':')) |colon_pos| {
            // Count colons - if more than one, it's a variant chain not a shorthand
            var colon_count: usize = 0;
            for (trimmed) |c| {
                if (c == ':') colon_count += 1;
            }
            if (colon_count == 1 and colon_pos > 0 and colon_pos < trimmed.len - 1) {
                // Make sure prefix is not a variant (otherwise hover:bg would become hover-bg)
                const prefix = trimmed[0..colon_pos];
                if (!isVariantPrefix(prefix)) {
                    return try self.expandColonShorthand(trimmed, colon_pos);
                }
            }
        }

        return null;
    }

    /// Expand bracket syntax: flex[col jc-center] → [flex-col, justify-center]
    /// Special handling for modifiers like min/max: h[min 100vh] → min-h-[100vh]
    fn expandBracketSyntax(self: *GroupedSyntaxParser, input: []const u8, bracket_start: usize) !?[][]const u8 {
        const prefix = input[0..bracket_start];

        // Find closing bracket
        const bracket_end = simd.simdFindMatchingBracket(input, bracket_start) orelse return null;
        const content = input[bracket_start + 1 .. bracket_end];

        if (content.len == 0) return null;

        var results: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (results.items) |item| self.allocator.free(item);
            results.deinit(self.allocator);
        }

        // Split content by spaces and expand each value
        var iter = std.mem.splitScalar(u8, content, ' ');
        var pending_modifier: ?[]const u8 = null;

        while (iter.next()) |value| {
            const trimmed_val = string_utils.trim(value);
            if (trimmed_val.len == 0) continue;

            // Check if this is a modifier that should combine with the next value
            if (isModifier(prefix, trimmed_val)) {
                pending_modifier = trimmed_val;
                continue;
            }

            // If we have a pending modifier, combine it with this value
            if (pending_modifier) |modifier| {
                const expanded = try self.expandValueWithModifier(prefix, modifier, trimmed_val);
                try results.append(self.allocator, expanded);
                pending_modifier = null;
            } else {
                const expanded = try self.expandValue(prefix, trimmed_val);
                try results.append(self.allocator, expanded);
            }
        }

        // Handle trailing modifier without value (shouldn't happen, but be safe)
        if (pending_modifier) |modifier| {
            const expanded = try self.expandValue(prefix, modifier);
            try results.append(self.allocator, expanded);
        }

        return try results.toOwnedSlice(self.allocator);
    }

    /// Check if a value is a modifier that should combine with the next value
    fn isModifier(prefix: []const u8, value: []const u8) bool {
        // For h/w prefixes, min/max are modifiers
        if (std.mem.eql(u8, prefix, "h") or std.mem.eql(u8, prefix, "w")) {
            return std.mem.eql(u8, value, "min") or std.mem.eql(u8, value, "max");
        }
        // For scroll prefix, x/y are modifiers
        if (std.mem.eql(u8, prefix, "scroll")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y");
        }
        // For p (padding) prefix, x/y/t/b/l/r/s/e are directional modifiers
        if (std.mem.eql(u8, prefix, "p")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y") or
                std.mem.eql(u8, value, "t") or std.mem.eql(u8, value, "b") or
                std.mem.eql(u8, value, "l") or std.mem.eql(u8, value, "r") or
                std.mem.eql(u8, value, "s") or std.mem.eql(u8, value, "e");
        }
        // For m (margin) prefix, x/y/t/b/l/r/s/e are directional modifiers
        if (std.mem.eql(u8, prefix, "m")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y") or
                std.mem.eql(u8, value, "t") or std.mem.eql(u8, value, "b") or
                std.mem.eql(u8, value, "l") or std.mem.eql(u8, value, "r") or
                std.mem.eql(u8, value, "s") or std.mem.eql(u8, value, "e");
        }
        // For rounded prefix, positional modifiers
        if (std.mem.eql(u8, prefix, "rounded")) {
            return std.mem.eql(u8, value, "t") or std.mem.eql(u8, value, "b") or
                std.mem.eql(u8, value, "l") or std.mem.eql(u8, value, "r") or
                std.mem.eql(u8, value, "tl") or std.mem.eql(u8, value, "tr") or
                std.mem.eql(u8, value, "bl") or std.mem.eql(u8, value, "br") or
                std.mem.eql(u8, value, "s") or std.mem.eql(u8, value, "e") or
                std.mem.eql(u8, value, "ss") or std.mem.eql(u8, value, "se") or
                std.mem.eql(u8, value, "es") or std.mem.eql(u8, value, "ee");
        }
        // For space prefix, x/y are modifiers
        if (std.mem.eql(u8, prefix, "space")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y");
        }
        // For gap prefix, x/y are modifiers
        if (std.mem.eql(u8, prefix, "gap")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y");
        }
        // For inset prefix, x/y/t/b/l/r are modifiers
        if (std.mem.eql(u8, prefix, "inset")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y") or
                std.mem.eql(u8, value, "t") or std.mem.eql(u8, value, "b") or
                std.mem.eql(u8, value, "l") or std.mem.eql(u8, value, "r");
        }
        // For ring prefix, "offset" is a modifier
        if (std.mem.eql(u8, prefix, "ring")) {
            return std.mem.eql(u8, value, "offset");
        }
        // For overflow prefix, x/y are modifiers
        if (std.mem.eql(u8, prefix, "overflow")) {
            return std.mem.eql(u8, value, "x") or std.mem.eql(u8, value, "y");
        }
        return false;
    }

    /// Expand a value with a modifier prefix: h[min 100vh] → min-h-[100vh]
    fn expandValueWithModifier(self: *GroupedSyntaxParser, prefix: []const u8, modifier: []const u8, value: []const u8) ![]const u8 {
        // For h/w with min/max, create min-h-[value] or max-w-[value]
        if (std.mem.eql(u8, prefix, "h") or std.mem.eql(u8, prefix, "w")) {
            if (isLikelySizeValue(value)) {
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}-[{s}]", .{ modifier, prefix, value });
            } else {
                // Check for known values like "full", "screen"
                if (ExpansionRules.h.get(value)) |expanded| {
                    if (!std.mem.eql(u8, expanded, "min-h") and !std.mem.eql(u8, expanded, "max-h") and
                        !std.mem.eql(u8, expanded, "min-w") and !std.mem.eql(u8, expanded, "max-w"))
                    {
                        // It's a complete value like "h-full" → min-h-full
                        const suffix = expanded[2..]; // Skip "h-" or "w-"
                        return try std.fmt.allocPrint(self.allocator, "{s}-{s}-{s}", .{ modifier, prefix, suffix });
                    }
                }
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}-{s}", .{ modifier, prefix, value });
            }
        }

        // For scroll with x/y, create overflow-x-auto or overflow-y-hidden
        if (std.mem.eql(u8, prefix, "scroll")) {
            return try std.fmt.allocPrint(self.allocator, "overflow-{s}-{s}", .{ modifier, value });
        }

        // For padding: p[x 4] → px-4, p[t 2] → pt-2
        if (std.mem.eql(u8, prefix, "p")) {
            if (ExpansionRules.p.get(modifier)) |dir_prefix| {
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ dir_prefix, value });
            }
        }

        // For margin: m[t 4] → mt-4, m[x auto] → mx-auto
        if (std.mem.eql(u8, prefix, "m")) {
            if (ExpansionRules.m.get(modifier)) |dir_prefix| {
                // Handle "auto" special case
                if (std.mem.eql(u8, dir_prefix, "m-auto")) {
                    return try self.allocator.dupe(u8, "m-auto");
                }
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ dir_prefix, value });
            }
        }

        // For rounded: rounded[t lg] → rounded-t-lg, rounded[tl xl] → rounded-tl-xl
        if (std.mem.eql(u8, prefix, "rounded")) {
            if (ExpansionRules.rounded.get(modifier)) |pos_prefix| {
                // pos_prefix is like "rounded-t", we need to append the size
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ pos_prefix, value });
            }
        }

        // For space: space[x 4] → space-x-4, space[y 2] → space-y-2
        if (std.mem.eql(u8, prefix, "space")) {
            if (ExpansionRules.space.get(modifier)) |dir_prefix| {
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ dir_prefix, value });
            }
        }

        // For gap: gap[x 4] → gap-x-4, gap[y 2] → gap-y-2
        if (std.mem.eql(u8, prefix, "gap")) {
            if (ExpansionRules.gap.get(modifier)) |dir_prefix| {
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ dir_prefix, value });
            }
        }

        // For inset: inset[x 0] → inset-x-0, inset[t 4] → top-4
        if (std.mem.eql(u8, prefix, "inset")) {
            if (ExpansionRules.inset.get(modifier)) |pos_prefix| {
                return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ pos_prefix, value });
            }
        }

        // For ring: ring[offset 2] → ring-offset-2
        if (std.mem.eql(u8, prefix, "ring")) {
            if (std.mem.eql(u8, modifier, "offset")) {
                return try std.fmt.allocPrint(self.allocator, "ring-offset-{s}", .{value});
            }
        }

        // For overflow: overflow[x hidden] → overflow-x-hidden
        if (std.mem.eql(u8, prefix, "overflow")) {
            return try std.fmt.allocPrint(self.allocator, "overflow-{s}-{s}", .{ modifier, value });
        }

        // Default fallback
        return try std.fmt.allocPrint(self.allocator, "{s}-{s}-{s}", .{ modifier, prefix, value });
    }

    /// Expand colon shorthand: bg:black → [bg-black]
    fn expandColonShorthand(self: *GroupedSyntaxParser, input: []const u8, colon_pos: usize) !?[][]const u8 {
        const prefix = input[0..colon_pos];
        const value = input[colon_pos + 1 ..];

        if (prefix.len == 0 or value.len == 0) return null;

        // Special handling for reset: prefix
        if (std.mem.eql(u8, prefix, "reset")) {
            const reset_class = try std.fmt.allocPrint(self.allocator, "reset-{s}", .{value});
            var results = try self.allocator.alloc([]const u8, 1);
            results[0] = reset_class;
            return results;
        }

        var results = try self.allocator.alloc([]const u8, 1);
        results[0] = try self.expandValue(prefix, value);
        return results;
    }

    /// Expand a single value based on prefix and expansion rules
    fn expandValue(self: *GroupedSyntaxParser, prefix: []const u8, value: []const u8) ![]const u8 {
        // Handle special modifiers in value

        // Check for important modifier: p[4!] → !p-4
        var is_important = false;
        var actual_value = value;
        if (value.len > 0 and value[value.len - 1] == '!') {
            is_important = true;
            actual_value = value[0 .. value.len - 1];
        }

        // Check for negative value: m[-4] → -m-4
        var is_negative = false;
        if (actual_value.len > 0 and actual_value[0] == '-') {
            is_negative = true;
            actual_value = actual_value[1..];
        }

        // Check for opacity modifier: bg[blue-500/50] → bg-blue-500/50
        // The slash notation passes through directly

        // Get the base expanded class
        const base_class = try self.expandValueInternal(prefix, actual_value);

        // Apply negative prefix if needed
        if (is_negative) {
            const negative_class = try std.fmt.allocPrint(self.allocator, "-{s}", .{base_class});
            self.allocator.free(base_class);

            // Apply important prefix if needed
            if (is_important) {
                const important_class = try std.fmt.allocPrint(self.allocator, "!{s}", .{negative_class});
                self.allocator.free(negative_class);
                return important_class;
            }
            return negative_class;
        }

        // Apply important prefix if needed
        if (is_important) {
            const important_class = try std.fmt.allocPrint(self.allocator, "!{s}", .{base_class});
            self.allocator.free(base_class);
            return important_class;
        }

        return base_class;
    }

    /// Internal expansion without negative/important handling
    fn expandValueInternal(self: *GroupedSyntaxParser, prefix: []const u8, value: []const u8) ![]const u8 {
        // Check for inner variant: flex[md:col] → md:flex-col
        if (simd.simdIndexOfScalar(value, ':')) |colon_pos| {
            const variant = value[0..colon_pos];
            const inner_value = value[colon_pos + 1 ..];

            // If it looks like a variant prefix, expand without it then prepend
            if (isVariantPrefix(variant)) {
                const base_expanded = try self.expandValueInternal(prefix, inner_value);
                defer self.allocator.free(base_expanded);
                return try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ variant, base_expanded });
            }
        }

        // Try to find expansion rules for this prefix
        if (std.mem.eql(u8, prefix, "flex")) {
            if (ExpansionRules.flex.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            // Check if value starts with gap- to pass through
            if (std.mem.startsWith(u8, value, "gap-")) {
                return try self.allocator.dupe(u8, value);
            }
        } else if (std.mem.eql(u8, prefix, "text")) {
            if (ExpansionRules.text.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            // Check for color values
            if (isLikelyColor(value)) {
                return try std.fmt.allocPrint(self.allocator, "text-{s}", .{value});
            }
            // Check for size values (numbers with units)
            if (isLikelySizeValue(value)) {
                return try std.fmt.allocPrint(self.allocator, "text-[{s}]", .{value});
            }
        } else if (std.mem.eql(u8, prefix, "h")) {
            if (ExpansionRules.h.get(value)) |expanded| {
                // Some are prefixes (min, max), some are full classes
                if (std.mem.eql(u8, expanded, "min-h") or std.mem.eql(u8, expanded, "max-h")) {
                    // This would be part of a multi-value like h[min 100vh]
                    return try self.allocator.dupe(u8, expanded);
                }
                return try self.allocator.dupe(u8, expanded);
            }
            // Check for viewport/percentage values
            if (isLikelySizeValue(value)) {
                return try std.fmt.allocPrint(self.allocator, "h-[{s}]", .{value});
            }
        } else if (std.mem.eql(u8, prefix, "w")) {
            if (ExpansionRules.w.get(value)) |expanded| {
                if (std.mem.eql(u8, expanded, "min-w") or std.mem.eql(u8, expanded, "max-w")) {
                    return try self.allocator.dupe(u8, expanded);
                }
                return try self.allocator.dupe(u8, expanded);
            }
            if (isLikelySizeValue(value)) {
                return try std.fmt.allocPrint(self.allocator, "w-[{s}]", .{value});
            }
        } else if (std.mem.eql(u8, prefix, "scroll")) {
            if (ExpansionRules.scroll.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
        } else if (std.mem.eql(u8, prefix, "bg")) {
            if (ExpansionRules.bg.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            // Colors pass through with bg- prefix
            if (isLikelyColor(value)) {
                return try std.fmt.allocPrint(self.allocator, "bg-{s}", .{value});
            }
        } else if (std.mem.eql(u8, prefix, "border")) {
            if (ExpansionRules.border.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            // Check if it's a width (number)
            if (value.len > 0 and std.ascii.isDigit(value[0])) {
                return try std.fmt.allocPrint(self.allocator, "border-{s}", .{value});
            }
            // Check if it's a color
            if (isLikelyColor(value)) {
                return try std.fmt.allocPrint(self.allocator, "border-{s}", .{value});
            }
        } else if (std.mem.eql(u8, prefix, "grid")) {
            if (ExpansionRules.grid.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            // Handle grid-cols-N etc
            if (std.mem.startsWith(u8, value, "cols-")) {
                return try std.fmt.allocPrint(self.allocator, "grid-{s}", .{value});
            }
            if (std.mem.startsWith(u8, value, "rows-")) {
                return try std.fmt.allocPrint(self.allocator, "grid-{s}", .{value});
            }
            // Handle gap values
            if (std.mem.startsWith(u8, value, "gap-")) {
                return try self.allocator.dupe(u8, value);
            }
        } else if (std.mem.eql(u8, prefix, "p")) {
            // Simple padding: p[4] → p-4
            if (ExpansionRules.p.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "p-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "m")) {
            // Simple margin: m[4] → m-4, m[auto] → m-auto
            if (ExpansionRules.m.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "m-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "rounded")) {
            // Simple rounded: rounded[lg] → rounded-lg
            if (ExpansionRules.rounded.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "rounded-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "space")) {
            // Simple space: space[4] → space-x-4 (default x)
            if (ExpansionRules.space.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "space-x-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "gap")) {
            // Simple gap: gap[4] → gap-4
            if (ExpansionRules.gap.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "gap-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "inset")) {
            // Simple inset: inset[0] → inset-0
            if (ExpansionRules.inset.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "inset-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "ring")) {
            // Ring: ring[2] → ring-2, ring[blue-500] → ring-blue-500
            if (ExpansionRules.ring.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            // Check if it's a color
            if (isLikelyColor(value)) {
                return try std.fmt.allocPrint(self.allocator, "ring-{s}", .{value});
            }
            return try std.fmt.allocPrint(self.allocator, "ring-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "transition")) {
            // Transition: transition[all] → transition-all, transition[300] → duration-300
            if (ExpansionRules.transition.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "transition-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "animate")) {
            // Animate: animate[spin] → animate-spin
            if (ExpansionRules.animate.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "animate-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "font")) {
            if (ExpansionRules.font.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "font-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "opacity")) {
            if (ExpansionRules.opacity.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "opacity-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "z")) {
            if (ExpansionRules.z.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "z-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "translate")) {
            if (ExpansionRules.translate.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "translate-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "rotate")) {
            if (ExpansionRules.rotate.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "rotate-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "scale")) {
            if (ExpansionRules.scale.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "scale-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "cursor")) {
            if (ExpansionRules.cursor.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "cursor-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "select")) {
            if (ExpansionRules.select.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "select-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "overflow")) {
            if (ExpansionRules.overflow.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "overflow-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "aspect")) {
            if (ExpansionRules.aspect.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "aspect-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "object")) {
            if (ExpansionRules.object.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "object-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "items")) {
            if (ExpansionRules.items.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "items-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "justify")) {
            if (ExpansionRules.justify.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "justify-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "content")) {
            if (ExpansionRules.content.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "content-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "self")) {
            if (ExpansionRules.self.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "self-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "place")) {
            if (ExpansionRules.place.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "place-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "order")) {
            if (ExpansionRules.order.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "order-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "tracking")) {
            if (ExpansionRules.tracking.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "tracking-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "leading")) {
            if (ExpansionRules.leading.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "leading-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "list")) {
            if (ExpansionRules.list.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "list-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "decoration")) {
            if (ExpansionRules.decoration.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "decoration-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "blur")) {
            if (ExpansionRules.blur.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "blur-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "brightness")) {
            if (ExpansionRules.brightness.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "brightness-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "contrast")) {
            if (ExpansionRules.contrast.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "contrast-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "saturate")) {
            if (ExpansionRules.saturate.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "saturate-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "grayscale")) {
            if (ExpansionRules.grayscale.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "grayscale-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "sepia")) {
            if (ExpansionRules.sepia.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "sepia-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "invert")) {
            if (ExpansionRules.invert.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "invert-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "backdrop")) {
            if (ExpansionRules.backdrop.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "backdrop-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "origin")) {
            if (ExpansionRules.origin.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "origin-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "duration")) {
            if (ExpansionRules.duration.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "duration-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "delay")) {
            if (ExpansionRules.delay.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "delay-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "ease")) {
            if (ExpansionRules.ease.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "ease-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "outline")) {
            if (ExpansionRules.outline.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "outline-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "shadow")) {
            if (ExpansionRules.shadow.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "shadow-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "pointer")) {
            if (ExpansionRules.pointer.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "pointer-events-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "resize")) {
            if (ExpansionRules.resize.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "resize-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "will")) {
            if (ExpansionRules.will.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "will-change-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "snap")) {
            if (ExpansionRules.snap.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "snap-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "touch")) {
            if (ExpansionRules.touch.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "touch-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "fill")) {
            if (ExpansionRules.fill.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "fill-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "stroke")) {
            if (ExpansionRules.stroke.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "stroke-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "columns")) {
            if (ExpansionRules.columns.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "columns-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "break")) {
            if (ExpansionRules.@"break".get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "break-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "drop-shadow")) {
            if (ExpansionRules.drop_shadow.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "drop-shadow-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "skew")) {
            if (ExpansionRules.skew.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "skew-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "accent")) {
            if (ExpansionRules.accent.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            if (isLikelyColor(value)) {
                return try std.fmt.allocPrint(self.allocator, "accent-{s}", .{value});
            }
            return try std.fmt.allocPrint(self.allocator, "accent-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "caret")) {
            if (ExpansionRules.caret.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            if (isLikelyColor(value)) {
                return try std.fmt.allocPrint(self.allocator, "caret-{s}", .{value});
            }
            return try std.fmt.allocPrint(self.allocator, "caret-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "appearance")) {
            if (ExpansionRules.appearance.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "appearance-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "overscroll")) {
            if (ExpansionRules.overscroll.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "overscroll-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "col")) {
            if (ExpansionRules.col.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "col-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "row")) {
            if (ExpansionRules.row.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "row-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "top")) {
            if (ExpansionRules.top.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "top-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "right")) {
            if (ExpansionRules.right.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "right-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "bottom")) {
            if (ExpansionRules.bottom.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "bottom-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "left")) {
            if (ExpansionRules.left.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "left-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "px")) {
            if (ExpansionRules.px.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "px-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "py")) {
            if (ExpansionRules.py.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "py-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "pt")) {
            if (ExpansionRules.pt.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "pt-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "pr")) {
            if (ExpansionRules.pr.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "pr-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "pb")) {
            if (ExpansionRules.pb.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "pb-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "pl")) {
            if (ExpansionRules.pl.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "pl-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "mx")) {
            if (ExpansionRules.mx.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "mx-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "my")) {
            if (ExpansionRules.my.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "my-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "mt")) {
            if (ExpansionRules.mt.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "mt-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "mr")) {
            if (ExpansionRules.mr.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "mr-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "mb")) {
            if (ExpansionRules.mb.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "mb-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "ml")) {
            if (ExpansionRules.ml.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "ml-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "underline")) {
            if (ExpansionRules.underline.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "underline-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "scroll-m")) {
            if (ExpansionRules.scroll_m.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "scroll-m-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "scroll-p")) {
            if (ExpansionRules.scroll_p.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "scroll-p-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "sr")) {
            if (ExpansionRules.sr.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "sr-{s}", .{value});
        } else if (std.mem.eql(u8, prefix, "hue-rotate")) {
            if (ExpansionRules.hue_rotate.get(value)) |expanded| {
                return try self.allocator.dupe(u8, expanded);
            }
            return try std.fmt.allocPrint(self.allocator, "hue-rotate-{s}", .{value});
        }

        // Default: prefix-value
        return try std.fmt.allocPrint(self.allocator, "{s}-{s}", .{ prefix, value });
    }

    /// Check if a string looks like a color value
    fn isLikelyColor(value: []const u8) bool {
        // Common color names
        const color_names = [_][]const u8{
            "white", "black",   "transparent", "current", "inherit",
            "slate", "gray",    "zinc",        "neutral", "stone",
            "red",   "orange",  "amber",       "yellow",  "lime",
            "green", "emerald", "teal",        "cyan",    "sky",
            "blue",  "indigo",  "violet",      "purple",  "fuchsia",
            "pink",  "rose",
        };

        // Check if starts with a color name
        for (color_names) |color| {
            if (std.mem.startsWith(u8, value, color)) {
                return true;
            }
        }

        // Check for hex color pattern
        if (value.len > 0 and value[0] == '#') return true;

        // Check for rgb/rgba/hsl patterns
        if (std.mem.startsWith(u8, value, "rgb") or
            std.mem.startsWith(u8, value, "hsl") or
            std.mem.startsWith(u8, value, "oklch"))
        {
            return true;
        }

        return false;
    }

    /// Check if a string looks like a size value (number with unit)
    fn isLikelySizeValue(value: []const u8) bool {
        if (value.len == 0) return false;

        // Check for numeric start
        if (std.ascii.isDigit(value[0])) return true;

        // Check for common CSS units
        const units = [_][]const u8{
            "px", "rem", "em",  "vh",  "vw",  "vmin", "vmax",
            "%",  "ch",  "ex",  "cm",  "mm",  "in",   "pt",
            "pc", "svh", "svw", "lvh", "lvw", "dvh",  "dvw",
        };

        for (units) |unit| {
            if (std.mem.endsWith(u8, value, unit)) {
                return true;
            }
        }

        return false;
    }
};

/// Convenience function to expand a class if it uses grouped syntax
pub fn expandGroupedSyntax(allocator: std.mem.Allocator, class_str: []const u8) !?[][]const u8 {
    var parser = GroupedSyntaxParser.init(allocator);
    return parser.parseAndExpand(class_str);
}

/// Process a list of classes, expanding any grouped syntax patterns
pub fn processClasses(allocator: std.mem.Allocator, classes: []const []const u8) ![][]const u8 {
    var result: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (result.items) |item| allocator.free(item);
        result.deinit(allocator);
    }

    var parser = GroupedSyntaxParser.init(allocator);

    for (classes) |class| {
        if (try parser.parseAndExpand(class)) |expanded| {
            defer allocator.free(expanded);
            for (expanded) |exp_class| {
                try result.append(allocator, exp_class);
            }
        } else {
            // Not grouped syntax, pass through as-is
            try result.append(allocator, try allocator.dupe(u8, class));
        }
    }

    return try result.toOwnedSlice(allocator);
}

// Tests
test "expandBracketSyntax flex" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("flex[col jc-center ai-center]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 3), expanded.len);
    try std.testing.expectEqualStrings("flex-col", expanded[0]);
    try std.testing.expectEqualStrings("justify-center", expanded[1]);
    try std.testing.expectEqualStrings("items-center", expanded[2]);
}

test "expandColonShorthand bg:black" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("bg:black")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("bg-black", expanded[0]);
}

test "expandBracketSyntax text" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("text[arial white 2rem 700]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 4), expanded.len);
    try std.testing.expectEqualStrings("font-[Arial]", expanded[0]);
    try std.testing.expectEqualStrings("text-white", expanded[1]);
    try std.testing.expectEqualStrings("text-[2rem]", expanded[2]);
    try std.testing.expectEqualStrings("font-bold", expanded[3]);
}

test "expandBracketSyntax w" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("w:100%")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("w-[100%]", expanded[0]);
}

test "expandBracketSyntax h" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("h[min 100vh]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    // min + 100vh should combine to min-h-[100vh]
    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("min-h-[100vh]", expanded[0]);
}

test "expandBracketSyntax scroll" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("scroll[y auto]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    // y + auto should combine to overflow-y-auto
    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("overflow-y-auto", expanded[0]);
}

test "reset utility" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("reset:meyer")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("reset-meyer", expanded[0]);
}

test "non-grouped syntax returns null" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    // Regular Tailwind classes shouldn't be expanded
    const result1 = try parser.parseAndExpand("flex");
    try std.testing.expect(result1 == null);

    const result2 = try parser.parseAndExpand("bg-blue-500");
    try std.testing.expect(result2 == null);

    // Variant chains are not colon shorthand
    const result3 = try parser.parseAndExpand("hover:bg-blue-500");
    try std.testing.expect(result3 == null);
}

test "inner variants: flex[md:col lg:row]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("flex[md:col lg:row]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 2), expanded.len);
    try std.testing.expectEqualStrings("md:flex-col", expanded[0]);
    try std.testing.expectEqualStrings("lg:flex-row", expanded[1]);
}

test "negative values: m[-4]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("m[-4]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("-m-4", expanded[0]);
}

test "important modifier: p[4!]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("p[4!]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("!p-4", expanded[0]);
}

test "negative important combined: m[-4!]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("m[-4!]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("!-m-4", expanded[0]);
}

test "overflow multiValue: overflow[x hidden]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("overflow[x hidden]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("overflow-x-hidden", expanded[0]);
}

test "opacity pass-through: bg[blue-500/50]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("bg[blue-500/50]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("bg-blue-500/50", expanded[0]);
}

test "responsive variant prefix: md:flex[col]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("md:flex[col]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("md:flex-col", expanded[0]);
}

test "hover variant prefix: hover:bg[blue-600]" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    const expanded = (try parser.parseAndExpand("hover:bg[blue-600]")).?;
    defer {
        for (expanded) |item| allocator.free(item);
        allocator.free(expanded);
    }

    try std.testing.expectEqual(@as(usize, 1), expanded.len);
    try std.testing.expectEqualStrings("hover:bg-blue-600", expanded[0]);
}

test "new utilities: cursor, select, opacity, z" {
    const allocator = std.testing.allocator;
    var parser = GroupedSyntaxParser.init(allocator);

    // cursor
    {
        const expanded = (try parser.parseAndExpand("cursor[pointer]")).?;
        defer {
            for (expanded) |item| allocator.free(item);
            allocator.free(expanded);
        }
        try std.testing.expectEqualStrings("cursor-pointer", expanded[0]);
    }

    // select
    {
        const expanded = (try parser.parseAndExpand("select[none]")).?;
        defer {
            for (expanded) |item| allocator.free(item);
            allocator.free(expanded);
        }
        try std.testing.expectEqualStrings("select-none", expanded[0]);
    }

    // opacity
    {
        const expanded = (try parser.parseAndExpand("opacity[50]")).?;
        defer {
            for (expanded) |item| allocator.free(item);
            allocator.free(expanded);
        }
        try std.testing.expectEqualStrings("opacity-50", expanded[0]);
    }

    // z-index
    {
        const expanded = (try parser.parseAndExpand("z[10]")).?;
        defer {
            for (expanded) |item| allocator.free(item);
            allocator.free(expanded);
        }
        try std.testing.expectEqualStrings("z-10", expanded[0]);
    }
}
