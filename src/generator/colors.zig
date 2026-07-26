const std = @import("std");

/// Complete Tailwind CSS v4 Color Palette
/// This module contains ALL colors from Tailwind CSS v4 using OKLCH color space
/// OKLCH format provides better perceptual uniformity and wider color gamut

// OKLCH color format: "L% C H" where:
// L = Lightness (0-100%)
// C = Chroma (color intensity, 0-0.4 typically)
// H = Hue (0-360 degrees)

/// Parse a color value like "blue-500" into color and shade
pub fn parseColorShade(value: []const u8) ?struct { color: []const u8, shade: []const u8 } {
    // Find last dash
    var i: usize = value.len;
    while (i > 0) {
        i -= 1;
        if (value[i] == '-') {
            return .{
                .color = value[0..i],
                .shade = value[i + 1 ..],
            };
        }
    }
    // No dash - might be special color like "white", "black", "transparent"
    return .{ .color = value, .shade = "" };
}

/// Resolve a color value to OKLCH string (e.g., "blue-500" -> "62.3% 0.214 259.815")
pub fn resolveColor(value: []const u8) ?[]const u8 {
    const parsed = parseColorShade(value) orelse return null;

    // Check special colors first
    if (std.mem.eql(u8, parsed.color, "inherit")) return "inherit";
    if (std.mem.eql(u8, parsed.color, "current")) return "currentColor";
    if (std.mem.eql(u8, parsed.color, "transparent")) return "transparent";
    if (std.mem.eql(u8, parsed.color, "black")) return "0% 0 0";
    if (std.mem.eql(u8, parsed.color, "white")) return "100% 0 0";

    // Try to find the color in the palette
    return getColorShade(parsed.color, parsed.shade);
}

fn getColorShade(color: []const u8, shade: []const u8) ?[]const u8 {
    // Red
    if (std.mem.eql(u8, color, "red")) {
        if (std.mem.eql(u8, shade, "50")) return "97.1% 0.013 17.38";
        if (std.mem.eql(u8, shade, "100")) return "93.6% 0.032 17.717";
        if (std.mem.eql(u8, shade, "200")) return "88.5% 0.062 18.334";
        if (std.mem.eql(u8, shade, "300")) return "80.8% 0.114 19.571";
        if (std.mem.eql(u8, shade, "400")) return "70.4% 0.191 22.216";
        if (std.mem.eql(u8, shade, "500")) return "63.7% 0.237 25.331";
        if (std.mem.eql(u8, shade, "600")) return "57.7% 0.245 27.325";
        if (std.mem.eql(u8, shade, "700")) return "50.5% 0.213 27.518";
        if (std.mem.eql(u8, shade, "800")) return "44.4% 0.177 26.899";
        if (std.mem.eql(u8, shade, "900")) return "39.6% 0.141 25.723";
        if (std.mem.eql(u8, shade, "950")) return "25.8% 0.092 26.042";
    }

    // Orange
    if (std.mem.eql(u8, color, "orange")) {
        if (std.mem.eql(u8, shade, "50")) return "98% 0.016 73.684";
        if (std.mem.eql(u8, shade, "100")) return "95.4% 0.038 75.164";
        if (std.mem.eql(u8, shade, "200")) return "90.1% 0.076 70.697";
        if (std.mem.eql(u8, shade, "300")) return "83.7% 0.128 66.29";
        if (std.mem.eql(u8, shade, "400")) return "75% 0.183 55.934";
        if (std.mem.eql(u8, shade, "500")) return "70.5% 0.213 47.604";
        if (std.mem.eql(u8, shade, "600")) return "64.6% 0.222 41.116";
        if (std.mem.eql(u8, shade, "700")) return "55.3% 0.195 38.402";
        if (std.mem.eql(u8, shade, "800")) return "47% 0.157 37.304";
        if (std.mem.eql(u8, shade, "900")) return "40.8% 0.123 38.172";
        if (std.mem.eql(u8, shade, "950")) return "26.6% 0.079 36.259";
    }

    // Amber
    if (std.mem.eql(u8, color, "amber")) {
        if (std.mem.eql(u8, shade, "50")) return "98.7% 0.022 95.277";
        if (std.mem.eql(u8, shade, "100")) return "96.2% 0.059 95.617";
        if (std.mem.eql(u8, shade, "200")) return "92.4% 0.12 95.746";
        if (std.mem.eql(u8, shade, "300")) return "87.9% 0.169 91.605";
        if (std.mem.eql(u8, shade, "400")) return "82.8% 0.189 84.429";
        if (std.mem.eql(u8, shade, "500")) return "76.9% 0.188 70.08";
        if (std.mem.eql(u8, shade, "600")) return "66.6% 0.179 58.318";
        if (std.mem.eql(u8, shade, "700")) return "55.5% 0.163 48.998";
        if (std.mem.eql(u8, shade, "800")) return "47.3% 0.137 46.201";
        if (std.mem.eql(u8, shade, "900")) return "41.4% 0.112 45.904";
        if (std.mem.eql(u8, shade, "950")) return "27.9% 0.077 45.635";
    }

    // Yellow
    if (std.mem.eql(u8, color, "yellow")) {
        if (std.mem.eql(u8, shade, "50")) return "98.7% 0.026 102.212";
        if (std.mem.eql(u8, shade, "100")) return "97.3% 0.071 103.193";
        if (std.mem.eql(u8, shade, "200")) return "94.5% 0.129 101.54";
        if (std.mem.eql(u8, shade, "300")) return "90.5% 0.182 98.111";
        if (std.mem.eql(u8, shade, "400")) return "85.2% 0.199 91.936";
        if (std.mem.eql(u8, shade, "500")) return "79.5% 0.184 86.047";
        if (std.mem.eql(u8, shade, "600")) return "68.1% 0.162 75.834";
        if (std.mem.eql(u8, shade, "700")) return "55.4% 0.135 66.442";
        if (std.mem.eql(u8, shade, "800")) return "47.6% 0.114 61.907";
        if (std.mem.eql(u8, shade, "900")) return "42.1% 0.095 57.708";
        if (std.mem.eql(u8, shade, "950")) return "28.6% 0.066 53.813";
    }

    // Lime
    if (std.mem.eql(u8, color, "lime")) {
        if (std.mem.eql(u8, shade, "50")) return "98.6% 0.031 120.757";
        if (std.mem.eql(u8, shade, "100")) return "96.7% 0.067 122.328";
        if (std.mem.eql(u8, shade, "200")) return "93.8% 0.127 124.321";
        if (std.mem.eql(u8, shade, "300")) return "89.7% 0.196 126.665";
        if (std.mem.eql(u8, shade, "400")) return "84.1% 0.238 128.85";
        if (std.mem.eql(u8, shade, "500")) return "76.8% 0.233 130.85";
        if (std.mem.eql(u8, shade, "600")) return "64.8% 0.2 131.684";
        if (std.mem.eql(u8, shade, "700")) return "53.2% 0.157 131.589";
        if (std.mem.eql(u8, shade, "800")) return "45.3% 0.124 130.933";
        if (std.mem.eql(u8, shade, "900")) return "40.5% 0.101 131.063";
        if (std.mem.eql(u8, shade, "950")) return "27.4% 0.072 132.109";
    }

    // Green
    if (std.mem.eql(u8, color, "green")) {
        if (std.mem.eql(u8, shade, "50")) return "98.2% 0.018 155.826";
        if (std.mem.eql(u8, shade, "100")) return "96.2% 0.044 156.743";
        if (std.mem.eql(u8, shade, "200")) return "92.5% 0.084 155.995";
        if (std.mem.eql(u8, shade, "300")) return "87.1% 0.15 154.449";
        if (std.mem.eql(u8, shade, "400")) return "79.2% 0.209 151.711";
        if (std.mem.eql(u8, shade, "500")) return "72.3% 0.219 149.579";
        if (std.mem.eql(u8, shade, "600")) return "62.7% 0.194 149.214";
        if (std.mem.eql(u8, shade, "700")) return "52.7% 0.154 150.069";
        if (std.mem.eql(u8, shade, "800")) return "44.8% 0.119 151.328";
        if (std.mem.eql(u8, shade, "900")) return "39.3% 0.095 152.535";
        if (std.mem.eql(u8, shade, "950")) return "26.6% 0.065 152.934";
    }

    // Emerald
    if (std.mem.eql(u8, color, "emerald")) {
        if (std.mem.eql(u8, shade, "50")) return "97.9% 0.021 166.113";
        if (std.mem.eql(u8, shade, "100")) return "95% 0.052 163.051";
        if (std.mem.eql(u8, shade, "200")) return "90.5% 0.093 164.15";
        if (std.mem.eql(u8, shade, "300")) return "84.5% 0.143 164.978";
        if (std.mem.eql(u8, shade, "400")) return "76.5% 0.177 163.223";
        if (std.mem.eql(u8, shade, "500")) return "69.6% 0.17 162.48";
        if (std.mem.eql(u8, shade, "600")) return "59.6% 0.145 163.225";
        if (std.mem.eql(u8, shade, "700")) return "50.8% 0.118 165.612";
        if (std.mem.eql(u8, shade, "800")) return "43.2% 0.095 166.913";
        if (std.mem.eql(u8, shade, "900")) return "37.8% 0.077 168.94";
        if (std.mem.eql(u8, shade, "950")) return "26.2% 0.051 172.552";
    }

    // Teal
    if (std.mem.eql(u8, color, "teal")) {
        if (std.mem.eql(u8, shade, "50")) return "98.4% 0.014 180.72";
        if (std.mem.eql(u8, shade, "100")) return "95.3% 0.051 180.801";
        if (std.mem.eql(u8, shade, "200")) return "91% 0.096 180.426";
        if (std.mem.eql(u8, shade, "300")) return "85.5% 0.138 181.071";
        if (std.mem.eql(u8, shade, "400")) return "77.7% 0.152 181.912";
        if (std.mem.eql(u8, shade, "500")) return "70.4% 0.14 182.503";
        if (std.mem.eql(u8, shade, "600")) return "60% 0.118 184.704";
        if (std.mem.eql(u8, shade, "700")) return "51.1% 0.096 186.391";
        if (std.mem.eql(u8, shade, "800")) return "43.7% 0.078 188.216";
        if (std.mem.eql(u8, shade, "900")) return "38.6% 0.063 188.416";
        if (std.mem.eql(u8, shade, "950")) return "27.7% 0.046 192.524";
    }

    // Cyan
    if (std.mem.eql(u8, color, "cyan")) {
        if (std.mem.eql(u8, shade, "50")) return "98.4% 0.019 200.873";
        if (std.mem.eql(u8, shade, "100")) return "95.6% 0.045 203.388";
        if (std.mem.eql(u8, shade, "200")) return "91.7% 0.08 205.041";
        if (std.mem.eql(u8, shade, "300")) return "86.5% 0.127 207.078";
        if (std.mem.eql(u8, shade, "400")) return "78.9% 0.154 211.53";
        if (std.mem.eql(u8, shade, "500")) return "71.5% 0.143 215.221";
        if (std.mem.eql(u8, shade, "600")) return "60.9% 0.126 221.723";
        if (std.mem.eql(u8, shade, "700")) return "52% 0.105 223.128";
        if (std.mem.eql(u8, shade, "800")) return "45% 0.085 224.283";
        if (std.mem.eql(u8, shade, "900")) return "39.8% 0.07 227.392";
        if (std.mem.eql(u8, shade, "950")) return "30.2% 0.056 229.695";
    }

    // Sky
    if (std.mem.eql(u8, color, "sky")) {
        if (std.mem.eql(u8, shade, "50")) return "97.7% 0.013 236.62";
        if (std.mem.eql(u8, shade, "100")) return "95.1% 0.026 236.824";
        if (std.mem.eql(u8, shade, "200")) return "90.1% 0.058 230.902";
        if (std.mem.eql(u8, shade, "300")) return "82.8% 0.111 230.318";
        if (std.mem.eql(u8, shade, "400")) return "74.6% 0.16 232.661";
        if (std.mem.eql(u8, shade, "500")) return "68.5% 0.169 237.323";
        if (std.mem.eql(u8, shade, "600")) return "58.8% 0.158 241.966";
        if (std.mem.eql(u8, shade, "700")) return "50% 0.134 242.749";
        if (std.mem.eql(u8, shade, "800")) return "44.3% 0.11 240.79";
        if (std.mem.eql(u8, shade, "900")) return "39.1% 0.09 240.876";
        if (std.mem.eql(u8, shade, "950")) return "29.3% 0.066 243.157";
    }

    // Blue
    if (std.mem.eql(u8, color, "blue")) {
        if (std.mem.eql(u8, shade, "50")) return "97% 0.014 254.604";
        if (std.mem.eql(u8, shade, "100")) return "93.2% 0.032 255.585";
        if (std.mem.eql(u8, shade, "200")) return "88.2% 0.059 254.128";
        if (std.mem.eql(u8, shade, "300")) return "80.9% 0.105 251.813";
        if (std.mem.eql(u8, shade, "400")) return "70.7% 0.165 254.624";
        if (std.mem.eql(u8, shade, "500")) return "62.3% 0.214 259.815";
        if (std.mem.eql(u8, shade, "600")) return "54.6% 0.245 262.881";
        if (std.mem.eql(u8, shade, "700")) return "48.8% 0.243 264.376";
        if (std.mem.eql(u8, shade, "800")) return "42.4% 0.199 265.638";
        if (std.mem.eql(u8, shade, "900")) return "37.9% 0.146 265.522";
        if (std.mem.eql(u8, shade, "950")) return "28.2% 0.091 267.935";
    }

    // Indigo
    if (std.mem.eql(u8, color, "indigo")) {
        if (std.mem.eql(u8, shade, "50")) return "96.2% 0.018 272.314";
        if (std.mem.eql(u8, shade, "100")) return "93% 0.034 272.788";
        if (std.mem.eql(u8, shade, "200")) return "87% 0.065 274.039";
        if (std.mem.eql(u8, shade, "300")) return "78.5% 0.115 274.713";
        if (std.mem.eql(u8, shade, "400")) return "67.3% 0.182 276.935";
        if (std.mem.eql(u8, shade, "500")) return "58.5% 0.233 277.117";
        if (std.mem.eql(u8, shade, "600")) return "51.1% 0.262 276.966";
        if (std.mem.eql(u8, shade, "700")) return "45.7% 0.24 277.023";
        if (std.mem.eql(u8, shade, "800")) return "39.8% 0.195 277.366";
        if (std.mem.eql(u8, shade, "900")) return "35.9% 0.144 278.697";
        if (std.mem.eql(u8, shade, "950")) return "25.7% 0.09 281.288";
    }

    // Violet
    if (std.mem.eql(u8, color, "violet")) {
        if (std.mem.eql(u8, shade, "50")) return "96.9% 0.016 293.756";
        if (std.mem.eql(u8, shade, "100")) return "94.3% 0.029 294.588";
        if (std.mem.eql(u8, shade, "200")) return "89.4% 0.057 293.283";
        if (std.mem.eql(u8, shade, "300")) return "81.1% 0.111 293.571";
        if (std.mem.eql(u8, shade, "400")) return "70.2% 0.183 293.541";
        if (std.mem.eql(u8, shade, "500")) return "60.6% 0.25 292.717";
        if (std.mem.eql(u8, shade, "600")) return "54.1% 0.281 293.009";
        if (std.mem.eql(u8, shade, "700")) return "49.1% 0.27 292.581";
        if (std.mem.eql(u8, shade, "800")) return "43.2% 0.232 292.759";
        if (std.mem.eql(u8, shade, "900")) return "38% 0.189 293.745";
        if (std.mem.eql(u8, shade, "950")) return "28.3% 0.141 291.089";
    }

    // Purple
    if (std.mem.eql(u8, color, "purple")) {
        if (std.mem.eql(u8, shade, "50")) return "97.6% 0.014 308.299";
        if (std.mem.eql(u8, shade, "100")) return "95.1% 0.027 307.174";
        if (std.mem.eql(u8, shade, "200")) return "90.6% 0.054 306.703";
        if (std.mem.eql(u8, shade, "300")) return "83.1% 0.105 305.542";
        if (std.mem.eql(u8, shade, "400")) return "72.3% 0.184 303.9";
        if (std.mem.eql(u8, shade, "500")) return "63.7% 0.25 302.321";
        if (std.mem.eql(u8, shade, "600")) return "56.9% 0.288 301.924";
        if (std.mem.eql(u8, shade, "700")) return "51.2% 0.278 302.016";
        if (std.mem.eql(u8, shade, "800")) return "44.6% 0.237 302.016";
        if (std.mem.eql(u8, shade, "900")) return "39.2% 0.193 303.9";
        if (std.mem.eql(u8, shade, "950")) return "28.8% 0.153 303.479";
    }

    // Fuchsia
    if (std.mem.eql(u8, color, "fuchsia")) {
        if (std.mem.eql(u8, shade, "50")) return "97.9% 0.014 318.852";
        if (std.mem.eql(u8, shade, "100")) return "95.5% 0.031 318.228";
        if (std.mem.eql(u8, shade, "200")) return "91.4% 0.062 317.977";
        if (std.mem.eql(u8, shade, "300")) return "85.3% 0.124 318.603";
        if (std.mem.eql(u8, shade, "400")) return "76.7% 0.223 319.851";
        if (std.mem.eql(u8, shade, "500")) return "67.5% 0.295 321.474";
        if (std.mem.eql(u8, shade, "600")) return "58.4% 0.313 322.222";
        if (std.mem.eql(u8, shade, "700")) return "51.3% 0.279 322.598";
        if (std.mem.eql(u8, shade, "800")) return "45% 0.234 322.598";
        if (std.mem.eql(u8, shade, "900")) return "39.8% 0.188 323.346";
        if (std.mem.eql(u8, shade, "950")) return "28.3% 0.142 324.47";
    }

    // Pink
    if (std.mem.eql(u8, color, "pink")) {
        if (std.mem.eql(u8, shade, "50")) return "97.8% 0.009 343.619";
        if (std.mem.eql(u8, shade, "100")) return "95.5% 0.023 342.098";
        if (std.mem.eql(u8, shade, "200")) return "92.2% 0.047 343.619";
        if (std.mem.eql(u8, shade, "300")) return "86.5% 0.097 346.661";
        if (std.mem.eql(u8, shade, "400")) return "77.8% 0.176 350.464";
        if (std.mem.eql(u8, shade, "500")) return "69.5% 0.214 353.506";
        if (std.mem.eql(u8, shade, "600")) return "61.8% 0.232 356.548";
        if (std.mem.eql(u8, shade, "700")) return "54.7% 0.211 0.381";
        if (std.mem.eql(u8, shade, "800")) return "47.8% 0.176 1.902";
        if (std.mem.eql(u8, shade, "900")) return "42.8% 0.144 3.423";
        if (std.mem.eql(u8, shade, "950")) return "29.5% 0.098 5.705";
    }

    // Rose
    if (std.mem.eql(u8, color, "rose")) {
        if (std.mem.eql(u8, shade, "50")) return "97.8% 0.007 12.422";
        if (std.mem.eql(u8, shade, "100")) return "95.2% 0.02 12.422";
        if (std.mem.eql(u8, shade, "200")) return "91.1% 0.044 10.901";
        if (std.mem.eql(u8, shade, "300")) return "84.5% 0.092 10.901";
        if (std.mem.eql(u8, shade, "400")) return "75% 0.161 10.901";
        if (std.mem.eql(u8, shade, "500")) return "66.6% 0.202 12.683";
        if (std.mem.eql(u8, shade, "600")) return "59.4% 0.215 14.464";
        if (std.mem.eql(u8, shade, "700")) return "52.4% 0.191 15.224";
        if (std.mem.eql(u8, shade, "800")) return "46.3% 0.161 13.643";
        if (std.mem.eql(u8, shade, "900")) return "41.5% 0.134 12.422";
        if (std.mem.eql(u8, shade, "950")) return "27.1% 0.086 11.661";
    }

    // Slate
    if (std.mem.eql(u8, color, "slate")) {
        if (std.mem.eql(u8, shade, "50")) return "98.4% 0.003 247.858";
        if (std.mem.eql(u8, shade, "100")) return "96.5% 0.007 247.896";
        if (std.mem.eql(u8, shade, "200")) return "93.1% 0.012 255.508";
        if (std.mem.eql(u8, shade, "300")) return "87.1% 0.019 252.894";
        if (std.mem.eql(u8, shade, "400")) return "68.4% 0.03 257.416";
        if (std.mem.eql(u8, shade, "500")) return "52.5% 0.033 257.337";
        if (std.mem.eql(u8, shade, "600")) return "41.4% 0.03 257.416";
        if (std.mem.eql(u8, shade, "700")) return "34.7% 0.026 257.337";
        if (std.mem.eql(u8, shade, "800")) return "27.8% 0.02 264.695";
        if (std.mem.eql(u8, shade, "900")) return "22.9% 0.015 264.695";
        if (std.mem.eql(u8, shade, "950")) return "13.6% 0.011 285.884";
    }

    // Gray
    if (std.mem.eql(u8, color, "gray")) {
        if (std.mem.eql(u8, shade, "50")) return "98.5% 0.002 247.839";
        if (std.mem.eql(u8, shade, "100")) return "96.8% 0.003 264.542";
        if (std.mem.eql(u8, shade, "200")) return "93.7% 0.006 264.531";
        if (std.mem.eql(u8, shade, "300")) return "87.8% 0.01 258.338";
        if (std.mem.eql(u8, shade, "400")) return "69.3% 0.014 261.325";
        if (std.mem.eql(u8, shade, "500")) return "53.6% 0.016 256.801";
        if (std.mem.eql(u8, shade, "600")) return "42.5% 0.014 257.281";
        if (std.mem.eql(u8, shade, "700")) return "35.2% 0.012 259.733";
        if (std.mem.eql(u8, shade, "800")) return "28.2% 0.009 259.087";
        if (std.mem.eql(u8, shade, "900")) return "23.2% 0.008 285.885";
        if (std.mem.eql(u8, shade, "950")) return "13.6% 0.005 285.885";
    }

    // Zinc
    if (std.mem.eql(u8, color, "zinc")) {
        if (std.mem.eql(u8, shade, "50")) return "98.9% 0.001 286.375";
        if (std.mem.eql(u8, shade, "100")) return "97.1% 0.002 286.375";
        if (std.mem.eql(u8, shade, "200")) return "94.1% 0.004 286.375";
        if (std.mem.eql(u8, shade, "300")) return "88.2% 0.007 286.375";
        if (std.mem.eql(u8, shade, "400")) return "70% 0.011 286.067";
        if (std.mem.eql(u8, shade, "500")) return "54.4% 0.012 285.938";
        if (std.mem.eql(u8, shade, "600")) return "43.4% 0.01 285.938";
        if (std.mem.eql(u8, shade, "700")) return "35.8% 0.008 286.067";
        if (std.mem.eql(u8, shade, "800")) return "28.6% 0.006 286.067";
        if (std.mem.eql(u8, shade, "900")) return "23.7% 0.005 286.067";
        if (std.mem.eql(u8, shade, "950")) return "14.1% 0.004 285.938";
    }

    // Neutral
    if (std.mem.eql(u8, color, "neutral")) {
        if (std.mem.eql(u8, shade, "50")) return "98.9% 0 0";
        if (std.mem.eql(u8, shade, "100")) return "97.1% 0 0";
        if (std.mem.eql(u8, shade, "200")) return "94.1% 0.001 106.424";
        if (std.mem.eql(u8, shade, "300")) return "88.3% 0.002 106.424";
        if (std.mem.eql(u8, shade, "400")) return "70.2% 0.003 106.424";
        if (std.mem.eql(u8, shade, "500")) return "54.6% 0.003 106.424";
        if (std.mem.eql(u8, shade, "600")) return "43.6% 0.003 106.424";
        if (std.mem.eql(u8, shade, "700")) return "36% 0.002 106.424";
        if (std.mem.eql(u8, shade, "800")) return "28.8% 0.001 106.424";
        if (std.mem.eql(u8, shade, "900")) return "23.9% 0.001 106.424";
        if (std.mem.eql(u8, shade, "950")) return "14.3% 0.001 106.424";
    }

    // Stone
    if (std.mem.eql(u8, color, "stone")) {
        if (std.mem.eql(u8, shade, "50")) return "98.9% 0.001 106.424";
        if (std.mem.eql(u8, shade, "100")) return "97.3% 0.002 106.424";
        if (std.mem.eql(u8, shade, "200")) return "94.5% 0.005 75.964";
        if (std.mem.eql(u8, shade, "300")) return "88.9% 0.007 75.96";
        if (std.mem.eql(u8, shade, "400")) return "70.7% 0.011 75.963";
        if (std.mem.eql(u8, shade, "500")) return "55.4% 0.012 56.363";
        if (std.mem.eql(u8, shade, "600")) return "44.4% 0.011 56.259";
        if (std.mem.eql(u8, shade, "700")) return "36.9% 0.009 56.259";
        if (std.mem.eql(u8, shade, "800")) return "29.6% 0.007 56.259";
        if (std.mem.eql(u8, shade, "900")) return "24.8% 0.006 56.363";
        if (std.mem.eql(u8, shade, "950")) return "14.9% 0.004 49.252";
    }

    return null;
}

// ============================================================================
// Backwards Compatibility Layer
// ============================================================================

/// Backwards compatibility: Check if a color exists
pub const colors = struct {
    pub fn has(color_name: []const u8) bool {
        const supported_colors = [_][]const u8{
            "red",         "orange", "amber", "yellow", "lime",    "green",  "emerald", "teal",
            "cyan",        "sky",    "blue",  "indigo", "violet",  "purple", "fuchsia", "pink",
            "rose",        "slate",  "gray",  "zinc",   "neutral", "stone",  "inherit", "current",
            "transparent", "black",  "white",
        };

        for (supported_colors) |color| {
            if (std.mem.eql(u8, color_name, color)) return true;
        }
        return false;
    }
};
