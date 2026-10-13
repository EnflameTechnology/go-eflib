# Enflame Management Library Go Bindings (go-eflib)

> **Language**: English | [中文](README_zh.md)

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Build and Package](#build-and-package)
  - [Use as a Dependency](#use-as-a-dependency)
- [Usage](#usage)
- [Key Features](#key-features)
- [Version Compatibility](#version-compatibility)
- [Hardware Support](#hardware-support)
- [Trouble Shooting](#trouble-shooting)
- [License](#license)

## Overview

`go-eflib` provides Go language bindings for **EFML (Enflame Management Library,
`libefml`)** — the Enflame counterpart to NVIDIA's go-nvml/NVML. It lets Go
programs query and manage Enflame GCU (General Compute Unit) devices: enumerate
the devices on a host and read per-device utilization, memory, temperature,
power, health and similar operational information.

The bindings are implemented as cgo wrappers over `libefml`:

- **Build-time headers** — the C headers (e.g. `efml.h`) are required when
  compiling a program that uses the bindings.
- **Runtime `dlopen`** — the shared library `libefml.so` is loaded at runtime via
  `dlopen` (the package links with `-ldl -Wl,--unresolved-symbols=ignore-in-object-files`),
  so `libefml.so` only has to be present on the machine that actually runs the
  program, not on the build machine.
- **Reusable foundation** — it is the common device-access layer beneath Enflame
  cloud components such as [gcu-exporter](../gcu-exporter) and
  [gcu-feature-discovery](../gcu-feature-discovery).

## Project Structure

```
go-eflib/
├── go-eflib_1.0/            # EFML Go bindings (cgo)
│   ├── (root package)       # go-eflib device-management API
│   └── efml/                # cgo code + bundled C headers (efml.h, ...)
├── LICENSE                  # Apache License 2.0
└── build.sh                 # Build + package entry point
```

- **`go-eflib_1.0/`** is the binding source. It has **no `go.mod`** and is
  consumed as a vendored/embedded library. The `efml/` subpackage holds the cgo
  code and the bundled C headers (such as `efml.h`).

## Installation

### Prerequisites

- **To build a consumer:** a C toolchain (the bindings use cgo) plus the EFML C
  headers (e.g. `efml.h`, bundled under `go-eflib_1.0/efml/`).
- **To run a consumer:** the Enflame GCU driver installed, with the EFML runtime
  library `libefml.so` present on the host (it is loaded via `dlopen`, so it is a
  runtime — not build-time — dependency).
- [Go](https://go.dev/) for building the consuming program.

### Build and Package

```bash
# Build and package the library under dist/
./build.sh all
```

The command produces the packaged library under `dist/`.

### Use as a Dependency

Because `go-eflib_1.0` has **no `go.mod`**, it is embedded directly into the
consumer as an internal/vendored package rather than imported through the Go
module mechanism. This is how [gcu-exporter](../gcu-exporter) and
[gcu-feature-discovery](../gcu-feature-discovery) consume it.

Remember the cgo split: the **C headers are needed at build time**, while
**`libefml.so` is loaded at runtime via `dlopen`** and therefore only has to be
present on the machine that runs the resulting binary.

## Usage

The snippet below is **illustrative only** — it shows the conceptual flow of
importing the package, initializing the library and enumerating devices. It is
not a literal API reference; consult the package source for the exact function
names and signatures.

```go
// Illustrative example — not a literal API reference.
package main

import (
	"fmt"

	eflib "go-eflib" // embedded go-eflib_1.0 package
)

func main() {
	// Initialize the EFML library (libefml.so is dlopen-ed at runtime).
	eflib.Init()
	defer eflib.Shutdown()

	// Enumerate the GCU devices present on the host.
	count := eflib.DeviceCount()
	for i := 0; i < count; i++ {
		// Read per-device information such as utilization, memory,
		// temperature, power and health status.
		fmt.Printf("GCU %d: <utilization / memory / temperature / power / health>\n", i)
	}
}
```

## Key Features

| Feature | Description |
| --- | --- |
| Device enumeration | List the Enflame GCU devices present on the host |
| Utilization & memory | Read per-device compute utilization and memory usage |
| Thermal & power | Read per-device temperature and power draw |
| Health status | Query per-device health for monitoring and alerting |
| cgo over EFML | Thin cgo wrappers over the `libefml` management library |
| Runtime dlopen | Loads `libefml.so` at runtime, so it is not a build-time dependency |

## Version Compatibility

`go-eflib_1.0` has **no `go.mod`** and is embedded/vendored into consumers as an
internal package. Because the bindings wrap EFML, their available capabilities
also track the installed Enflame GCU driver and `libefml.so` version on the host.
Match the runtime library to the deployed GCU driver.

## Hardware Support

Supports Enflame GCU devices that provide the Enflame GCU driver together with
the EFML runtime library (`libefml.so`). The same bindings work across GCU
product generations; the exact information available depends on the driver and
EFML version installed on the host.

## Trouble Shooting

- **`libefml.so` not found at runtime** — the shared library is loaded via
  `dlopen` at runtime. Ensure the Enflame GCU driver / EFML management library is
  installed and that `libefml.so` is on the library search path of the machine
  running the program.
- **Missing C headers at build time** — compiling a consumer requires the EFML C
  headers (e.g. `efml.h`). Make sure the bundled headers (under
  `go-eflib_1.0/efml/`) or an equivalent EFML SDK are available to the C toolchain.
- **cgo build failures** — the bindings require a working C toolchain. Verify a C
  compiler is installed and that cgo is enabled in the build environment.

## License

`go-eflib` is licensed under the **Apache License 2.0**. Copyright (c) Enflame
Technology. All Rights Reserved. See [LICENSE](LICENSE).
