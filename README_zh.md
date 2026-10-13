# 燧原管理库 Go 绑定 (go-eflib)

> **语言**: [English](README.md) | 中文

## 目录

- [概述](#概述)
- [项目结构](#项目结构)
- [安装](#安装)
  - [前置条件](#前置条件)
  - [构建与打包](#构建与打包)
  - [作为依赖使用](#作为依赖使用)
- [使用方法](#使用方法)
- [核心特性](#核心特性)
- [版本兼容性](#版本兼容性)
- [硬件支持](#硬件支持)
- [故障排查](#故障排查)
- [许可证](#许可证)

## 概述

`go-eflib` 为 **EFML（燧原管理库，Enflame Management Library，`libefml`）** 提供 Go
语言绑定——它是 NVIDIA go-nvml/NVML 在燧原侧的对应物。它让 Go 程序能够查询和管理燧原
GCU（通用计算单元，General Compute Unit）设备：枚举主机上的设备，并读取每张设备的利用率、
显存、温度、功耗、健康状态等运行信息。

该绑定以 cgo 封装 `libefml` 实现：

- **构建期头文件**——编译使用该绑定的程序时，需要 C 头文件（如 `efml.h`）。
- **运行期 `dlopen`**——共享库 `libefml.so` 在运行时通过 `dlopen` 加载（该包以
  `-ldl -Wl,--unresolved-symbols=ignore-in-object-files` 链接），因此 `libefml.so`
  只需在实际运行程序的机器上存在，而无需出现在构建机器上。
- **可复用的基础层**——它是燧原云组件（如 [gcu-exporter](../gcu-exporter) 与
  [gcu-feature-discovery](../gcu-feature-discovery)）之下通用的设备访问层。

## 项目结构

```
go-eflib/
├── go-eflib_1.0/            # EFML Go 绑定（cgo）
│   ├── (根包)               # go-eflib 设备管理 API
│   └── efml/                # cgo 代码 + 内置 C 头文件（efml.h 等）
├── LICENSE                  # Apache License 2.0
└── build.sh                 # 构建 + 打包入口
```

- **`go-eflib_1.0/`** 是绑定源码。它**没有 `go.mod`**，以 vendored/内嵌库的方式被使用。
  其 `efml/` 子包持有 cgo 代码以及内置的 C 头文件（如 `efml.h`）。

## 安装

### 前置条件

- **构建消费方时：** 需要 C 工具链（绑定使用 cgo）以及 EFML C 头文件（如 `efml.h`，内置于
  `go-eflib_1.0/efml/` 下）。
- **运行消费方时：** 需安装燧原 GCU 驱动，并且主机上存在 EFML 运行时库 `libefml.so`
  （它通过 `dlopen` 加载，属于运行期依赖而非构建期依赖）。
- 用于构建消费程序的 [Go](https://go.dev/)。

### 构建与打包

```bash
# 构建并将库打包到 dist/ 下
./build.sh all
```

该命令会在 `dist/` 下生成打包后的库。

### 作为依赖使用

由于 `go-eflib_1.0` **没有 `go.mod`**，它被直接内嵌到消费方中作为内部/vendored 包使用，
而非通过 Go 模块机制导入。[gcu-exporter](../gcu-exporter) 与
[gcu-feature-discovery](../gcu-feature-discovery) 即以此方式使用它。

请记住 cgo 的分工：**C 头文件在构建期需要**，而 **`libefml.so` 在运行期通过 `dlopen` 加载**，
因此后者只需在运行最终二进制的机器上存在。

## 使用方法

下面的代码片段**仅供示意**——它展示了导入包、初始化库、枚举设备的概念性流程，并非字面意义上的
API 参考；请以包源码为准，查阅确切的函数名与签名。

```go
// 示意性示例——并非字面意义上的 API 参考。
package main

import (
	"fmt"

	eflib "go-eflib" // 内嵌的 go-eflib_1.0 包
)

func main() {
	// 初始化 EFML 库（libefml.so 在运行时被 dlopen 加载）。
	eflib.Init()
	defer eflib.Shutdown()

	// 枚举主机上存在的 GCU 设备。
	count := eflib.DeviceCount()
	for i := 0; i < count; i++ {
		// 读取每张设备的利用率、显存、温度、功耗、健康状态等信息。
		fmt.Printf("GCU %d: <利用率 / 显存 / 温度 / 功耗 / 健康状态>\n", i)
	}
}
```

## 核心特性

| 特性 | 说明 |
| --- | --- |
| 设备枚举 | 列出主机上存在的燧原 GCU 设备 |
| 利用率与显存 | 读取每张设备的计算利用率与显存占用 |
| 温度与功耗 | 读取每张设备的温度与功耗 |
| 健康状态 | 查询每张设备的健康状态，用于监控与告警 |
| cgo 封装 EFML | 对 `libefml` 管理库的轻量 cgo 封装 |
| 运行期 dlopen | 运行时加载 `libefml.so`，因此并非构建期依赖 |

## 版本兼容性

`go-eflib_1.0` **没有 `go.mod`**，以内部包形式内嵌/vendored 到消费方中。由于绑定封装了
EFML，其可用能力也随主机上安装的燧原 GCU 驱动与 `libefml.so` 版本而变化。请将运行时库与
部署的 GCU 驱动相匹配。

## 硬件支持

支持提供燧原 GCU 驱动以及 EFML 运行时库（`libefml.so`）的燧原 GCU 设备。同一份绑定可跨
GCU 产品代际工作；可获取的具体信息取决于主机上安装的驱动与 EFML 版本。

## 故障排查

- **运行时找不到 `libefml.so`**——该共享库在运行时通过 `dlopen` 加载。请确认已安装燧原
  GCU 驱动 / EFML 管理库，并且 `libefml.so` 位于运行程序机器的库搜索路径中。
- **构建期缺少 C 头文件**——编译消费方需要 EFML C 头文件（如 `efml.h`）。请确保内置头文件
  （位于 `go-eflib_1.0/efml/` 下）或等价的 EFML SDK 对 C 工具链可见。
- **cgo 构建失败**——绑定需要可用的 C 工具链。请确认已安装 C 编译器，且构建环境中启用了
  cgo。

## 许可证

`go-eflib` 采用 **Apache License 2.0** 许可证。版权所有 (c) Enflame Technology，
保留所有权利。详见 [LICENSE](LICENSE)。
