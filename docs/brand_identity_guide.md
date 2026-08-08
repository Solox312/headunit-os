# HeadUnit OS — Brand Identity & Design System Guide 🚗📱

This document defines the complete visual identity, brand essence, color palette, typography hierarchy, UI motifs, and voice guidelines for **HeadUnit OS**.

---

## 01. 🌟 Brand Essence

> **Mission Statement:**  
> *HeadUnit OS exists so that **any** car can have a factory-grade dashboard — built on hardware you already own, software you can read, and a screen that stays legible at 70 mph after dark.*

### Core Pillars & Traits

1. **Instrument-Grade (Precise, not decorative)**:
   - Every visual choice reads like calibrated equipment — deliberate contrast, exact alignment, zero ornamental clutter. The brand looks engineered because the product is.
2. **After-Dark Honest (Night mode first)**:
   - Dark isn't a theme option — it's the default reality of driving. The identity commits to dark mode fully rather than treating dark mode as an afterthought.
3. **Open by Design (Transparent, not corporate)**:
   - No proprietary gloss. The system exposes its own construction — mono-spaced data, visible structure — the way open-source software exposes code.

---

## 02. 🎨 Color Tokens & Palette System

Dash Black carries the brand (~65% of any surface). Electric Cyan is the primary "on" signal. Dongle Violet and Native Green are reserved functional signals for hardware states.

| Token Name | Role / Function | Hex Code | HSL / Usage |
| :--- | :--- | :--- | :--- |
| **Dash Black** | Base background for all screens | `#0B0E14` | Main dark surface (`var(--bg)`) |
| **Panel Base** | Container & card background | `#151B26` | Base panel layer (`var(--panel)`) |
| **Glass Panel** | Elevated tiles, cards, badges | `#1B2230` | Glassmorphism tile layer (`var(--panel2)`) |
| **Panel Dark** | Data blocks, terminal, mono containers | `#0F1420` | Dark contrast panel (`var(--panel3)`) |
| **Stroke (Hairline)** | 1px border lines & card edges | `#262E3D` | Structural borders (`var(--stroke)`) |
| **Stroke Soft** | Dividers & subtle separators | `#1D2432` | Soft dividers (`var(--stroke-soft)`) |
| **Electric Cyan** | Primary accent — native / default path | `#00E5D4` | Primary control glow & active states |
| **Dongle Violet** | Hardware-bridge dongle signal | `#B18CFF` | Carlinkit / Hardware bridge indicator |
| **Native Green** | $0 / No-hardware confirmation | `#3DDC84` | Status OK & native wireless confirmation |
| **Text Primary** | Main headings & primary body text | `#E9EDF5` | High-contrast readable text |
| **Text Secondary** | Subtitles, labels, and muted copy | `#8A93A6` | Secondary labels |
| **Text Muted** | Metadata, timestamps, mono data | `#5C6579` | Subdued data details |

---

## 03. 🔤 Typography System

Three roles, three distinct Google Font families:

```
┌───────────────────┬──────────────────────────┬──────────────────────────────────────────────────┐
│ Role              │ Font Family              │ Standard Weights & Sizes                         │
├───────────────────┼──────────────────────────┼──────────────────────────────────────────────────┤
│ Display / Header  │ Space Grotesk            │ 700 Bold / 18px – 40px (Letter-spacing: -0.5px)  │
│ Body & Controls   │ Inter                    │ 400 Reg, 600 Semi / 13px – 16px                  │
│ Monospace / Data  │ JetBrains Mono           │ 400 Reg, 500 Medium / 10px – 13px                │
└───────────────────┴──────────────────────────┴──────────────────────────────────────────────────┘
```

### Type Scale Breakdown

- **Display XL (40px / 700 Bold - Space Grotesk)**: Main brand titles & hero headers.
- **Heading (26px / 700 Bold - Space Grotesk)**: Screen titles & major card headers.
- **Subhead (18px / 600 SemiBold - Space Grotesk)**: Widget titles & section labels.
- **Body (15px / 400 Regular - Inter)**: General text, descriptions, & control options.
- **Caption / Mono (11px – 13px / 500 - JetBrains Mono)**: Frequencies, telemetry data, resolutions, timestamps, and status bar text.

---

## 04. 🧩 UI Motif & Control Anatomy

1. **Glass Tiles**:
   - `14px` border radius across cards and tiles.
   - `1px` stroke in `#262E3D` (Hairline).
   - `#1B2230` elevated glass panel background.
2. **Icon Badges**:
   - Icons sit inside dedicated `48px – 56px` rounded badge containers, never floating bare.
   - Standard 24px icon inside a badge container.
3. **Corner Reticles**:
   - Subtle cyan bracket corners (`dtoverlay` reticle marks) reserved for sensing/auto-detect and calibration interfaces.
4. **Automotive Touch Target Scale**:
   - Primary interactive controls: **64px** minimum tap height.
   - Secondary controls: **48px** minimum tap height.
   - *Never render interactive controls smaller than 48px for driver safety.*

---

## 05. 🎯 Voice & Tone Guidelines

Direct, technically confident, never salesy. HeadUnit OS describes what it does in plain, verifiable terms.

| Say This (Do) | Avoid This (Don't) |
| :--- | :--- |
| *"Wireless Android Auto, no dongle needed."* | *"Revolutionary next-gen connectivity experience."* |
| *"Boots to kiosk mode in about 10 seconds."* | *"Blazing-fast, industry-leading boot times."* |
| *"Falls back to native wireless if no dongle is plugged in."* | *"Smart AI-powered auto-magic detection."* |
| *"MIT licensed. Fork it, flash it, ship it."* | *"Join our exclusive open-source community today!"* |

---

## 📚 References & Links

- HTML Brand Identity File: `file:///C:/Users/cnieves.wmg/Downloads/HeadUnitOS_Brand_Identity.html#essence`
- Theme Implementation: [automotive_theme.dart](file:///c:/Users/cnieves.wmg/Desktop/Projects/headunit-os/lib/theme/automotive_theme.dart)
- Color Implementation: [automotive_colors.dart](file:///c:/Users/cnieves.wmg/Desktop/Projects/headunit-os/lib/theme/automotive_colors.dart)
