# 开发操作手册

> 项目：Bookkeeper 记账本 | 包名：com.bookkeeper.bookkeeper
> Flutter SDK：D:\office\flutter | Android SDK：D:/office/Android/SDK

---

## 一、环境检查

```bash
# 检查 Flutter 环境是否正常
flutter doctor -v

# 查看 Flutter 版本
flutter --version

# 检查已连接的 Android 设备
flutter devices

# 检查 ADB 连接的设备
adb devices
```

---

## 二、依赖管理

```bash
# 安装/更新依赖（修改 pubspec.yaml 后必须执行）
flutter pub get

# 查看依赖是否有冲突
flutter pub deps

# 升级所有依赖到兼容版本
flutter pub upgrade

# 升级到最新版本（可能有破坏性变更）
flutter pub major-upgrade

# 清除依赖缓存（遇到奇怪的依赖问题时）
flutter clean
flutter pub get
```

---

## 三、代码生成

项目使用 drift (SQLite ORM) 和 Riverpod，修改表定义或 Provider 后需要重新生成代码。

```bash
# 一次性生成（构建前执行）
dart run build_runner build --delete-conflicting-outputs

# 监听模式（开发时常开，修改文件自动重新生成）
dart run build_runner watch --delete-conflicting-outputs

# 清除旧的生成文件后重新生成
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**什么时候需要跑代码生成：**
- 修改了 `core/database/` 下的表定义
- 新增或修改了 `@riverpod` 注解的 Provider
- 修改了 drift DAO 的查询方法

---

## 四、运行与调试

```bash
# Debug 模式运行（USB 调试，支持热重载）
flutter run

# 指定设备运行
flutter run -d <device-id>
flutter run -d emulator-5554        # 模拟器
flutter run -d <手机序列号>          # 真机

# 仅在真机上运行（release profile，性能更好）
flutter run --profile

# 热重载（运行中按 r）
# 热重启（运行中按 R）
# 完全重启（运行中按 q 退出后重新 flutter run）
```

---

## 五、构建 APK

```bash
# Debug APK（开发测试用，包含调试信息）
flutter build apk --debug

# Release APK（发布用，体积小、优化）
flutter build apk --release

# Profile APK（性能分析用）
flutter build apk --profile
```

**构建产物位置：**
```
build/app/outputs/flutter-apk/
├── app-debug.apk          # Debug 包
├── app-release.apk        # Release 包
└── app-profile.apk        # Profile 包
```

**一键安装到手机：**
```bash
# 构建并安装 debug 包
flutter run --debug

# 或者手动安装已构建的 APK
adb install build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk   # -r 覆盖安装
```

---

## 六、ADB 常用命令

### 设备管理

```bash
# 查看已连接设备
adb devices

# 查看设备详细信息
adb shell getprop ro.product.model       # 手机型号
adb shell getprop ro.build.version.sdk   # Android 版本号
adb shell getprop ro.build.display.id    # 系统版本

# 无线调试（Android 11+）
adb tcpip 5555
adb connect <手机IP>:5555
adb disconnect
```

### 应用管理

```bash
# 安装 APK
adb install path/to/app.apk
adb install -r path/to/app.apk          # 覆盖安装
adb install -t path/to/app.apk          # 允许安装测试包

# 卸载应用
adb uninstall com.bookkeeper.bookkeeper

# 清除应用数据（恢复初始状态）
adb shell pm clear com.bookkeeper.bookkeeper

# 查看应用包信息
adb shell dumpsys package com.bookkeeper.bookkeeper | head -20
```

### 文件操作

```bash
# 拉取文件到电脑
adb pull /sdcard/Download/notification_log.txt ./
adb pull /data/data/com.bookkeeper.bookkeeper/databases/ ./databases/

# 推送文件到手机
adb push local_file.txt /sdcard/Download/

# 查看手机存储文件
adb shell ls /sdcard/Download/
adb shell ls /data/data/com.bookkeeper.bookkeeper/databases/
```

### 日志与调试

```bash
# 实时查看日志（全部）
adb logcat

# 按 TAG 过滤日志
adb logcat -s PaymentNotifListener:D
adb logcat -s flutter:D

# 清除历史日志
adb logcat -c

# 查看日志并输出到文件（解决 Windows 中文乱码）
adb logcat -s PaymentNotifListener:D > log.txt

# 查看 Activity 栈
adb shell dumpsys activity activities | grep -A 5 "bookkeeper"

# 查看内存使用
adb shell dumpsys meminfo com.bookkeeper.bookkeeper

# 截图
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./

# 录屏
adb shell screenrecord /sdcard/record.mp4    # Ctrl+C 停止
adb pull /sdcard/record.mp4 ./
```

### 通知监听服务相关

```bash
# 查看通知监听权限状态
adb shell settings get secure enabled_notification_listeners

# 检查本应用是否在列表中
adb shell settings get secure enabled_notification_listeners | grep bookkeeper

# 查看服务运行状态
adb shell dumpsys notification | grep -A 3 "PaymentNotifListener"

# 强制停止应用（测试服务独立运行）
adb shell am force-stop com.bookkeeper.bookkeeper
# 通知监听服务仍会运行（系统级服务，不受 force-stop 影响）
```

---

## 七、数据库操作

### 查看数据库文件

```bash
# 数据库文件位置
adb shell ls /data/data/com.bookkeeper.bookkeeper/databases/

# 拉取到电脑
adb pull /data/data/com.bookkeeper.bookkeeper/databases/bookkeeper.db ./
adb pull /data/data/com.bookkeeper.bookkeeper/databases/pending_payments.db ./
```

### 清除数据库（重置应用数据）

```bash
# 方式 1：通过 ADB
adb shell pm clear com.bookkeeper.bookkeeper

# 方式 2：在手机上 → 设置 → 应用 → 记账本 → 清除数据
```

### Android Studio Database Inspector

1. 用 Debug 模式运行 APP
2. Android Studio → **View → Tool Windows → App Inspection**
3. 选择 **Database Inspector** 标签
4. 可以直接查看和执行 SQL 查询

---

## 八、代码质量

```bash
# 静态分析（检查代码错误和警告）
flutter analyze

# 格式化代码
dart format lib/

# 格式化并显示差异
dart format lib/ --output=show

# 只检查不修改
dart format lib/ --output=none --set-exit-if-changed
```

---

## 九、Git 操作

```bash
# 查看状态
git status
git diff                      # 查看未暂存的修改
git diff --staged             # 查看已暂存的修改

# 提交
git add <file1> <file2>       # 暂存指定文件
git commit -m "feat: 描述"    # 提交

# 查看历史
git log --oneline -10         # 最近 10 条提交
git log --oneline --all       # 所有分支的提交

# 分支操作
git branch                    # 查看本地分支
git branch <name>             # 创建分支
git checkout <name>           # 切换分支
git checkout -b <name>        # 创建并切换分支
git merge <name>              # 合并分支

# 撤销操作
git checkout -- <file>        # 撤销工作区修改
git reset HEAD <file>         # 取消暂存
git stash                     # 暂存当前修改
git stash pop                 # 恢复暂存的修改
```

---

## 十、常见问题排查

### 构建失败

```bash
# 清除构建缓存
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 如果 Gradle 报错
cd android
./gradlew clean
cd ..
flutter pub get
flutter build apk --debug
```

### 依赖冲突

```bash
# 查看依赖树，找出冲突
flutter pub deps

# 强制解析依赖
flutter pub get --enforce-lockfile
```

### 应用崩溃

```bash
# 查看崩溃日志
adb logcat -s flutter:E AndroidRuntime:E

# 查看 ANR 日志
adb shell ls /data/anr/
adb pull /data/anr/traces.txt ./
```

### 通知监听服务不工作

```bash
# 1. 检查权限
adb shell settings get secure enabled_notification_listeners | grep bookkeeper

# 2. 检查服务状态
adb shell dumpsys notification | grep "PaymentNotifListener"

# 3. 重新授权（跳转设置页后手动开关）
# APP 内：设置 → 智能记账 → 开启通知监听

# 4. 重启服务（关闭再打开通知监听权限）
```

### 数据库升级报错

```bash
# 如果数据库版本升级失败，清除数据重来
adb shell pm clear com.bookkeeper.bookkeeper
# 或在手机上卸载重装
```

---

## 十一、项目关键路径速查

| 内容 | 路径 |
|------|------|
| Flutter 入口 | `lib/main.dart` |
| 路由定义 | `lib/app/router/app_router.dart` |
| 数据库定义 | `lib/core/database/app_database.dart` |
| 表定义 | `lib/core/database/tables/` |
| 主题/颜色 | `lib/core/theme/app_colors.dart` |
| Provider 注册 | `lib/app/di/providers.dart` |
| Android 原生代码 | `android/app/src/main/kotlin/com/bookkeeper/bookkeeper/` |
| 通知监听服务 | `android/.../PaymentNotificationListenerService.kt` |
| 通知文本解析器 | `android/.../PaymentNotificationParser.kt` |
| MethodChannel 桥接 | `android/.../MainActivity.kt` |
| 构建产物 | `build/app/outputs/flutter-apk/` |
| 数据库文件 | `/data/data/com.bookkeeper.bookkeeper/databases/` |

---

## 十二、环境变量速查

| 变量 | 值 |
|------|-----|
| Flutter SDK | `D:\office\flutter` |
| Android SDK | `D:/office/Android/SDK` |
| Java 版本 | JDK 17 |
| 包名 | `com.bookkeeper.bookkeeper` |
| 数据库名 | `bookkeeper.db`（主库）/ `pending_payments.db`（待确认） |
| MethodChannel | `com.bookkeeper.bookkeeper/payment_notification` |
