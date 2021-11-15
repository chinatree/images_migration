# 镜像推拉工具

该工具主要实现了**批量**对镜像的拉取、TAG、推送、删除、清单等功能，以解决镜像从源仓库克隆至目标仓库时，繁琐的人工操作问题。

## 功能

- [x] 镜像单架构批量克隆
- [x] 镜像多架构批量克隆

## 帮助

- images-tool.sh

```bash
$ ./images-tool.sh -h
Usage:     
    ./images-tool.sh [-a <all|list|pull|tag|push|rmi|pull_tag>] [-pf <1|0>] [-f <image list file>]     
      -a, --action            do action, default: list     
      -pf, --platform         type for enable or disable plarform check and insert to path, default: 1     
      -f                      image list file, default: hub_to_harbor_common.list     

action:     
    all                       contains pull、tag、push action     
    pull_tag                  contains pull、tag action     
    list                      list iamges     
    pull                      pull images     
    tag                       tag images     
    push                      push images     
    rmi                       deletes images     
    ./images-tool.sh -a all     
    ./images-tool.sh -a pull_tag -pf=0     
    ./images-tool.sh -a pull -pf=0     
    ./images-tool.sh -a tag -pf=0 -f hub_to_harbor_common.list
```

- images-tool-multiarch.sh

```bash
./images-tool-multiarch.sh -h
Usage:     
    ./images-tool-multiarch.sh [-a <all|list|pull|tag|push|rmi|pull_tag|manifest>] [-f <image list file>] [--stage <all|create|annotate|push|rm>]     
      -a, --action            do action, default: list     
      -f                      image list file, default: hub_to_harbor_common.list     

action:     
    all                       contains pull、tag、push、manifest action     
    pull_tag                  contains pull、tag action     
    list                      list iamges     
    pull                      pull images     
    tag                       tag images     
    push                      push images     
    rmi                       deletes images     
    
    manifest                  make docker image manifests     
    
    ./images-tool-multiarch.sh -a all     
    ./images-tool-multiarch.sh -a pull_tag     
    ./images-tool-multiarch.sh -a pull     
    ./images-tool-multiarch.sh -a tag -f hub_to_harbor_common.list     
    
    ./images-tool-multiarch.sh -a manifest --stage all -f hub_to_harbor_common.list     
    ./images-tool-multiarch.sh -a manifest --stage create     
    ./images-tool-multiarch.sh -a manifest --stage annotate     
    ./images-tool-multiarch.sh -a manifest --stage push     
    ./images-tool-multiarch.sh -a manifest --stage rm
```

## 配置

### 格式

```ini
NAME|TAG|ARCHS|PULL_HOST|PULL_PREFIX|PUSH_HOST|PUSH_PREFIX|STAGE_PREFIX|EXTEND_TAGS
```

- 一个镜像一行配置，需要批量克隆时写多行
- `#` 开头表示注释，将被脚本忽略

### 说明

- `NAME`: 镜像名称
- `TAG`: 标签，如 `1.0.0`
- `ARCHS`: 架构，多个以逗号分隔，如 `amd64,arm64`
- `PULL_HOST`: 源仓库地址，`hub.docker.com` 的镜像则留空
- `PULL_PREFIX`: 源仓库地址相对路径，`hub.docker.com` 的镜像则留空
- `PUSH_HOST`:目标仓库地址，如 `harbor.yuntree.com`
- `PUSH_PREFIX`: 目标仓库相对路径，如 `common`
- `STAGE_PREFIX`: 目标仓库相对路径(多架构临时中转存放)，如 `stage`
- `EXTEND_TAGS`: 扩展标签，如`latest`

## 样例

### 单架构

> 该场景根据执行脚本的主机的CPU架构，从源仓库拉取对应的架构的镜像，TAG并推送至目标仓库。

```bash
# 需求
# 自动识别架构，并将识别的架构的 alpine:3.14.3 的镜像克隆至私有仓库
alpine:3.14.3 --> harbor.yuntree.com/common/<arch>/alpine:3.14.3
alpine:3.14.3 --> harbor.yuntree.com/common/<arch>/alpine:latest

# 配置示例
# 单架构场景， ARCHS、STAGE_PREFIX 配置项用不到，可留空
========================
# NAME|TAG|ARCHS|PULL_HOST|PULL_PREFIX|PUSH_HOST|PUSH_PREFIX|STAGE_PREFIX|EXTEND_TAGS
alpine|3.14.3|amd64,arm64|||harbor.yuntree.com|common|stage|latest
========================

# 执行命令
./images-tool.sh -f hub_to_harbor_common.list -pf 0 -a pull
./images-tool.sh -f hub_to_harbor_common.list -pf 0 -a tag
./images-tool.sh -f hub_to_harbor_common.list -pf 0 -a push
./images-tool.sh -f hub_to_harbor_common.list -pf 0 -a rmi
```

### 多架构

> 该场景根据配置指定的架构，从源仓库拉取相应的架构的镜像，TAG并推送至目标仓库，同时制作镜像清单推送至目标仓库。

```bash
# 需求
# 将 alpine:3.14.3 指定的 amd64，arm64 的镜像克隆至私有仓库
alpine:3.14.3 --> harbor.yuntree.com/common/alpine:3.14.3
alpine:3.14.3 --> harbor.yuntree.com/common/alpine:latest

# 配置示例
========================
# NAME|TAG|ARCHS|PULL_HOST|PULL_PREFIX|PUSH_HOST|PUSH_PREFIX|STAGE_PREFIX|EXTEND_TAGS
alpine|3.14.3|amd64,arm64|||harbor.yuntree.com|common|stage|latest
========================

# 执行命令
./image_tool_multiarch.sh -f hub_to_harbor_common.list -a pull
./image_tool_multiarch.sh -f hub_to_harbor_common.list -a tag
./image_tool_multiarch.sh -f hub_to_harbor_common.list -a push
./image_tool_multiarch.sh -f hub_to_harbor_common.list -a rmi
./image_tool_multiarch.sh -f hub_to_harbor_common.list -a manifest --stage all
```

## 协议

Dnsctl is released under the very permissive [MIT license](https://github.com/chinatree/dnsctl/blob/master/LICENSE).
