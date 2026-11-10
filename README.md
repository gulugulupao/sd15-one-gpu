# SD15 文生图 · Intel 核显离线镜像

一个容器装好网页界面、推理引擎和管理进程，在 NAS 上离线跑 SD1.5 文生图。只用 Intel 核显，不需要 NPU，不联网拉模型。

![生成结果](assets/demo-03-result.png)

## 先读这段

- **镜像不含模型权重**：需自行准备 `OpenVINO/stable-diffusion-v1-5-int8-ov`（约 2.2GB），目录结构见下。
- **内存**：16GB 才能稳定出图。8GB 机型能打开网页、能加载模型，但会被内存保护拦下，**不建议部署**。
- **架构**：x86_64（amd64），ARM 机型暂不支持。

## 获取镜像

在线拉取（推荐）：

```bash
docker pull mingmate/sd15-one-gpu:2026-11-09
```

Docker Hub 页面：https://hub.docker.com/r/mingmate/sd15-one-gpu

国内网络不稳时，用本仓库 Releases 里的 `sd15-one-gpu_2026-11-09.tar` 离线导入：

```bash
docker load -i sd15-one-gpu_2026-11-08.tar
```

导入后的镜像名是 `sd15-one-gpu:local`，把下面命令里的镜像名换成它即可。

## 绿联 NAS 推荐：用「项目」导入（别用一键运行）

绿联 Docker 的「镜像 → 运行」不会自动挂模型卷，容器起来也会报模型加载失败。请改用 **Docker → 项目 → 创建**，把 [`compose.ugnas-project.yaml`](compose.ugnas-project.yaml) 的内容粘进编辑器再部署。该文件已把模型卷、`extra_hosts`、核显、单端口、不设 `mem_limit` 全部预设好，卷用相对路径，换存储池也不用改。

模型要放在向导生成的项目目录里：`ovms-models/config.json`（0 字节空文件）+ `ovms-models/OpenVINO/stable-diffusion-v1-5-int8-ov/`（26 个文件），并在同目录建 0 字节 `state.json`。完整五步见 [`绿联NAS-项目部署.md`](绿联NAS-项目部署.md)。

> 2026-11-09 起镜像带启动自检：即使有人仍用一键运行，WebUI 也会直接指出缺什么、怎么补，不再显示「OVMS 退出码 1 + Python sys.path」。

## 不想手动放模型？用在线自动拉模型版

把 [`compose.ugnas-online.yaml`](compose.ugnas-online.yaml) 粘进绿联「项目 → 创建」即可。它多一个 `init-model` 服务，首次部署自动从 **ModelScope（国内直连、免登录）** 把 2.2GB 模型下载到项目目录，自动建好 0 字节 `config.json` 和 `state.json`，下完才启动主服务；重跑只补缺失文件，支持断点续传。

> 实测（2026-11-10，国内网络无代理）：清单 API 与文件下载均免登录，26 个模型文件与本项目逐项一致；但速度约 **1.1~1.4 MB/s**，首次下载约 **25~30 分钟**，并发不能提升。它解决的是「下载失败 / 手动放文件出错」，不是「下载极快」。追求速度请用离线包方式（把模型包放到国内网盘后解压到项目目录，再用 `compose.ugnas-project.yaml`）。


## 只想点一下？用模型内置的一键版

```bash
docker pull mingmate/sd15-one-gpu:2026-11-10-full
```

绿联 Docker「镜像 → 运行」直接创建容器即可：**不用挂模型卷、不用准备任何文件**。镜像内置 2.2GB 模型权重，GUI 会自动透传核显设备；实测不挂任何卷时 `/models` 已存在、启动自检通过、WebUI 正常。

- 镜像约 **3.8GB**，一次拉完；国内请先在 NAS 上配好 Docker Hub 镜像加速器。
- **不要再挂 `/models` 卷**，否则会把镜像内置的模型覆盖掉。
- 模型权重按 CreativeML Open RAIL-M 授权，镜像内 `/models/LICENSE-MODEL-OpenRAIL-M.txt` 随附；再分发与商用前请阅读并遵守其使用限制。
- 16GB 内存门槛不变，8GB 机型仍不建议部署。

## 国内下载最稳：离线分卷包

如果 Docker Hub 大模型或在线模型源都很慢，用离线分卷：模型包切成多个 200MB 小文件，哪个没下好只重下哪一个，不用整包重来。随包附许可证、`restore_model.sh` 恢复脚本与 `compose.ugnas-offline.yaml`。完整步骤见 [`绿联NAS-离线部署说明.md`](绿联NAS-离线部署说明.md)。

> 三种方式对比：在线自动拉模型版（`compose.ugnas-online.yaml`）省事但 ModelScope 实测约 1.1~1.4 MB/s、2.3GB 约 25~30 分钟；一键版（full tag）只需一次 Hub 拉取但要 3.8GB；离线分卷走国内网盘最快、最不容易失败。


## 部署

1. 把模型放好（结构必须一致）：

   ```
   <模型基目录>/config.json                              ← 0 字节空文件
   <模型基目录>/OpenVINO/stable-diffusion-v1-5-int8-ov/  ← 25 个模型文件
   ```

2. 用仓库里的 [`compose.registry.gpu.yaml`](compose.registry.gpu.yaml) 起服务，或直接用：

   ```bash
   docker run -d --name SD15-One-GPU \
     --restart unless-stopped \
     -p 7860:7860 \
     --add-host host.docker.internal:host-gateway \
     -v <模型基目录>:/models:ro \
     -v <state.json 文件>:/tmp/sd_one_state.json \
     --device /dev/dri:/dev/dri \
     mingmate/sd15-one-gpu:2026-11-09
   ```

   四样别漏：宿主机名映射、模型卷只读挂载、`state.json` 必须是文件（不能是目录）、`/dev/dri` 透传；**不要设 mem_limit**。

3. 浏览器打开 `http://<NAS 地址>:7860`。

网页标题是「SD15 · 文生图（本地 Intel 核显，模型离线）」，推理后端只有 GPU 一项。如果状态区提示模型加载失败，先检查第 1 步的目录和文件是否齐全。

## 运行演示

正向提示词 → 负面提示词 → 点生成，512×512、20 步、GPU 约 23 秒出图。

![输入正向提示词](assets/demo-01-prompt.png)

![输入负面提示词](assets/demo-02-negative.png)

![生成结果](assets/demo-03-result.png)

## 许可与署名

- 整合代码：MIT + 附加保护条款（署名保留、禁止商用等）→ [`LICENSE.txt`](LICENSE.txt)
- 模型权重：CreativeML Open RAIL-M → [`LICENSE-MODEL-OpenRAIL-M.txt`](LICENSE-MODEL-OpenRAIL-M.txt)
- 框架：Gradio / OpenVINO Model Server / OpenVINO（Apache-2.0）
- 部署整合：很多问题的小明同学 · https://github.com/gulugulupao/
