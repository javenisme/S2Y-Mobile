# 框架代码审阅

## Package.swift 概览
- 产品：`Spezi`, `SpeziTesting`, `XCTSpezi`
- 依赖：`SpeziFoundation (>=2.1.8)`, `XCTRuntimeAssertions (>=2.0.0)`, `swift-collections/OrderedCollections`
- Swift 设置：启用 `ExistentialAny`
- SwiftLint 插件通过环境变量可选启用

## 关键类型与文件
- `Sources/Spezi/Module/Module.swift`
  - `public protocol Module: AnyObject { @MainActor func configure() }`
  - 默认空实现，建议在 `configure()` 中启动异步任务
- `Sources/Spezi/Standard/Standard.swift`
  - `public protocol Standard: Actor, Module { }`
- `Sources/Spezi/Standard/Module+Standard.swift`
  - `typealias StandardActor = _StandardPropertyWrapper`，提供 `@StandardActor` 访问
- `Sources/Spezi/Spezi/Spezi.swift`
  - `@Observable final class Spezi`
  - 装载/卸载：`loadModule`, `unloadModule`，内部 `loadModules`, `_unloadModule`
  - 视图修饰符收集与注入：`_viewModifiers` 与 `viewModifiers`
  - 依赖变更传播：`handleCollectedValueRemoval`, 依赖解除处理 `handleDependencyUninjection`
  - 初始化使用 `withModuleInitContext` 提供模块上下文（影响 `logger` 类别等）
- `Sources/Spezi/Spezi/Spezi+Logger.swift`
  - `var logger: Logger` 根据 `moduleInitContext` 返回模块命名空间的 `Logger`

## Capabilities（属性包装器）
- `@Application` (`ApplicationPropertyWrapper.swift`)
  - 访问 `Spezi` 上下文属性；在注入时可根据 KeyPath 选择创建 shadow copy（如 `logger`, `launchOptions`）
- `@Provide` / `@Collect`（`ProvidePropertyWrapper.swift`, `CollectPropertyWrapper.swift`）
  - `@Provide` 支持 Optional/Collection，注入时写入共享存储；清理时触发移除回调
  - `@Collect` 在 `configure()` 期间读取并聚合匹配类型值
- `@Dependency`（`DependencyPropertyWrapper.swift`, `Module+Dependencies.swift`）
  - 支持必选、可选、默认值与集合构建，注入/解除注入均通过 `DependencyManager` 协调

## 依赖解析与模块存储
- 模块索引与弱引用管理通过 `StoredModulesKey`、`DynamicReference`、`ModuleReference`
- `SpeziStorage` 基于 `SpeziFoundation` 的共享仓库实现键化存储
- 隐式创建模块集合保存在 `implicitlyCreatedModules`，用于在无人依赖时递归卸载

## SwiftUI 集成
- 使用 `SpeziAppDelegate` 与 `View.spezi(appDelegate)` 将配置合并到根视图
- `EnvironmentAccessible` 模块会自动注入对应的环境修饰符，外部所有权（`.external`）不允许此类模块

## 运行时约束与防御
- 多处使用 `precondition`/`fatalError` 防御误用：
  - 在 `configure()` 中禁止装/卸载模块
  - 在访问窗口之外访问 `@Collect` 抛出失败
  - 依赖缺失或类型不匹配时报错

## 建议的代码阅读路径
1. `Package.swift` -> 了解产品与依赖
2. `Spezi.swift` -> 掌握装载/卸载、注入、视图修饰与事件
3. `Module.swift`、`Standard.swift` -> 理解基本协议
4. `Capabilities/*` -> 数据、应用、视图、可观察能力
5. `Dependencies/*` -> 依赖声明到注入的完整链路