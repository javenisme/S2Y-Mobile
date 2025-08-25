# 架构深度分析

## 概览
- **项目类型**: Swift Package (SwiftPM)
- **平台**: iOS 17+, visionOS 1, macOS 14, tvOS 17, watchOS 10
- **核心产物**: `Spezi`, `SpeziTesting`, `XCTSpezi`
- **外部依赖**: SpeziFoundation, XCTRuntimeAssertions, swift-collections (OrderedCollections)

## 包与目录结构
- `Sources/Spezi/`
  - `Module/` 定义 `Module` 协议及其扩展
  - `Standard/` 定义 `Standard` 协议与 `@StandardActor` 访问
  - `Capabilities/` 横切能力（`@Application`, `@Provide`, `@Collect`, View/Observable 等）
  - `Dependencies/` 依赖声明、收集与注入（`@Dependency`、解析器、管理器）
  - `Configuration/` 应用级配置入口 `Configuration`
  - `Spezi/` 核心 `Spezi` 类，负责模块装载/卸载、存储、生命周期与 SwiftUI 集成
  - `Utilities/` 应用代理适配、类型别名、动态引用等通用工具
  - `Notifications/` 远程通知注册与注销接口
  - `Spezi.docc/` 文档
- `Sources/SpeziTesting/` 测试配套（含 DocC）
- `Sources/XCTSpezi/` XCTest 辅助导出
- `Tests/` 包括 `SpeziTests/`、`UITests/`

## 核心概念
- **Module**
  - 面向功能的可重用子系统；生命周期入口为 `configure()`（主线程）
  - 可通过能力与依赖与其他模块交互
- **Standard**
  - 满足各模块共同契约的中枢协调者，`Actor & Module`
- **Spezi (App Runtime)**
  - 负责模块装载、依赖解析、数据通道收集、SwiftUI 环境注入与视图修饰
  - 暴露 `logger`、`launchOptions`、`spezi` 等应用级属性

## 能力模型（Capabilities）
- **@Application(\.keyPath)**: 在 `configure()` 及之后访问应用级属性/动作（如 `logger`, `spezi`）
- **@Provide / @Collect**: 无强依赖的数据通道
  - `@Provide` 在初始化期设置值；支持 Optional 与 Array 形态
  - `@Collect` 仅在 `configure()` 内可访问，聚合所有提供者的匹配值
- 视图与可观察支持：`EnvironmentAccessible`、`@Model`、`@Modifier` 等由 `Spezi` 统一收集并注入 SwiftUI

## 依赖关系（Dependencies）
- 通过 `@Dependency` 声明：
  - 必选依赖：`@Dependency(Other.self) var other`
  - 可选依赖：`@Dependency(Other.self) var other: Other?`
  - 默认值：`@Dependency var other = Other()`
  - 计算集合：`@Dependency { ModuleA(); ModuleB() } var deps: [any Module]`
- 依赖解析过程在装载前进行，支持隐式创建（记录于 `implicitlyCreatedModules`，在合适时机递归卸载）

## 数据流与生命周期
- 装载流程（简化）：
  1) 构建依赖管理器并解析依赖
  2) 第一次遍历：收集各模块的 `@Provide` 值到共享存储
  3) 注入应用上下文与已收集数据到模块
  4) 调用 `configure()` 完成轻量初始化
  5) 注册服务模块与 SwiftUI 修饰器/环境注入
  6) 通知既有模块刷新其 `@Collect` 值
- 卸载流程：
  - 校验依赖关系，禁止卸载仍被要求的模块
  - 清理视图修饰符、解除注入、更新可选依赖、根据隐式创建关系递归卸载
- 运行期：
  - `Spezi.run()` 驱动服务模块生命周期
  - `@Provide` 值清除后触发存储与收集方的更新

## SwiftUI 集成
- 通过 `@ApplicationDelegateAdaptor(SpeziAppDelegate.self)` + `View.spezi(appDelegate)` 将配置注入根视图
- 模块的环境可访问与视图修饰由 `Spezi` 汇总并统一注入，顺序经反转以满足依赖内外部访问语义

## 错误与断言
- 使用 `RuntimeAssertions` 在访问窗口、类型转换、装载时机等位置进行前置条件校验
- 依赖不满足、在 `configure()` 期间装/卸载模块等情况会触发失败

## 关键设计权衡
- 强约束的生命周期窗口保证简单可预测的数据注入（如 `@Collect` 只在 `configure()` 有效）
- 用 `Provide/Collect` 分离数据流与依赖关系，降低耦合
- 通过 `Spezi` 统一收口 SwiftUI 环境注入与视图修饰，避免散乱的全局状态

## 适配与扩展点
- 自定义 `Standard` 以定义全局协作契约
- 扩展能力（新 PropertyWrapper）以接入其他系统能力
- 借助依赖构建器约束模块集合的协议能力