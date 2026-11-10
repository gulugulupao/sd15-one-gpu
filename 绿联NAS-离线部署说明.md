# 绿联 NAS 离线部署（下载最快、最不容易失败）

适合国内网络拉 Docker Hub 大镜像或模型很慢、容易断的情况。模型包分成多个小文件，哪个没下好只重下哪一个，不用整包重来。

## 准备

- 一台 **16GB 内存**的 x86_64 绿联 NAS。8GB 机型能打开网页但出不了图，不建议装。
- 下载这几样，全部放到同一个文件夹：
  - `sd15-model-layer.tar.part00` … 到最后一份（模型分卷）
  - `SHA256SUMS-MODEL.txt`、`SHA256SUMS-FULL.txt`
  - `LICENSE-MODEL-OpenRAIL-M.txt`（模型许可证，恢复脚本会放进模型目录）
  - `restore_model.sh`
  - `compose.ugnas-offline.yaml`
  - 可选：`sd15-one-gpu_2026-11-09.tar`（镜像离线包，连 1.4GB 镜像都不想从网上拉时才用）

## 五步装好

1. 打开 **Docker → 项目 → 创建**，项目名填 `sd15`，记下向导生成的存放路径，先别点部署。
2. 打开「文件管理」，把上面下载的东西**全部**放进那个项目目录。
3. 在这个目录里打开终端，执行：

   ```
   sh restore_model.sh
   ```

   它会自动校验分卷、合并、解压，并建好 `ovms-models/` 和 0 字节 `state.json`。看到「完成」再往下走。

4. **镜像二选一**：
   - 网络还行：跳过这步，让项目自动从 Docker Hub 拉镜像（约 1.4GB）。
   - 想完全离线：打开 Docker →「镜像」→ 导入，选 `sd15-one-gpu_2026-11-09.tar`，导入后镜像名是 `sd15-one-gpu:local`。

5. 回到项目创建向导，把 `compose.ugnas-offline.yaml` 的内容整段粘进 Compose 配置，点 **立即部署**。等模型加载约 1 分钟，浏览器打开 `http://<NAS地址>:7860`，状态区显示「加载成功」就能出图了。

## 常见问题

- **恢复脚本报分卷校验失败**：只重新下载提示的那一个 `.part` 文件，不用全部重下。
- **状态区提示「还没准备好」**：说明 `ovms-models/` 没放对位置或文件不全，重跑一次恢复脚本。
- **别用 Docker「镜像 → 运行」的一键方式**：它不会自动挂模型卷。用「项目」粘贴 compose 才不会漏配置。
- **别把 `state.json` 建成文件夹**，也别给容器设内存限制。

## 许可

模型权重按 CreativeML Open RAIL-M 授权，随包附 `LICENSE-MODEL-OpenRAIL-M.txt`，再分发时请一并保留、并遵守其使用限制。项目整合代码的许可证见 `LICENSE.txt`。
