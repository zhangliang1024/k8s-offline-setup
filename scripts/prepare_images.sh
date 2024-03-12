#!/bin/bash
###
 # @Author: zhangliang
 # @Date: 2023-02-17 10:19:02
 # @LastEditors: zhangliang102411@126.com
 # @LastEditTime: 2024-03-12 09:35:09
 # @FilePath: \k8s-offline-setup\scripts\prepare_images.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by www.jingyou.com, All Rights Reserved. 
### 

# 在 资源准备节点执行，准备搭建K8S环境镜像

echo -e "-----------Docker环境准备----------- \n"
# 卸载旧版本
sudo yum remove docker*
# 安装基础依赖
sudo yum -y install vim net-tools yum-utils device-mapper-persistent-data lvm2
# 配置docker的yum地址
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 安装docker
sudo yum install -y docker-ce-23.0.0 docker-ce-cli-23.0.0 containerd.io-1.6.16

# 配置damon.json
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.nju.edu.cn/",
    "https://82m9ar63.mirror.aliyuncs.com",
    "https://kuamavit.mirror.aliyuncs.com"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "data-root":"/home/docker/lib"
}
EOF

# 启动docker
sudo systemctl enable docker && systemctl daemon-reload && systemctl restart docker
sudo docker version && docker info|grep systemd

docker rmi -f $(docker images -q)
rm -rf k8sOfflineSetup/images/*
docker system prune

echo -e "----------- K8S 镜像准备----------- \n"
# 定义镜像保存目录
image_dir="/root/k8sOfflineSetup/images"

# 检查镜像保存目录是否存在，如果不存在则创建
if [ ! -d "$image_dir" ]; then
    mkdir -p "$image_dir"
    echo "Created image directory: $image_dir"
else
    echo "Image directory already exists: $image_dir"
fi

# 读取 images.txt 文件中的每一行
while IFS= read -r line; do
    # 忽略以 "#" 开头的注释行和空行
    if [[ $line =~ ^\s*# ]] || [[ -z $line ]]; then
        echo "Skipping comment or empty line"
        continue
    fi
    
    echo "Processing image: $line"

    original_image_name="$line"

    # 检查是否是 registry.k8s.io 仓库的镜像
    if [[ $line == registry.k8s.io* ]]; then
        # 替换为 registry.cn-hangzhou.aliyuncs.com/google_containers 仓库的镜像
        pull_image_name=$(echo "$line" | sed 's|registry.k8s.io|registry.cn-hangzhou.aliyuncs.com/google_containers|')
        echo "Pulling image from $pull_image_name"
        # 特别处理 coredns 镜像
        if [[ $line == *coredns:* ]]; then
            pull_image_name=$(echo "$line" | sed 's|registry.k8s.io/coredns/coredns|registry.cn-hangzhou.aliyuncs.com/google_containers/coredns|')
            echo "Pulling image from $pull_image_name"
        fi

        # 拉取镜像
        docker pull "$pull_image_name"

        # 检查镜像是否成功拉取
        if [ $? -eq 0 ]; then
            echo "Image pulled successfully: $pull_image_name"

            # 如果使用了 registry.k8s.io 仓库，恢复原始镜像
            if [[ $original_image_name == registry.k8s.io* ]]; then
                echo "Original image name: $original_image_name"
                echo "Pulled image name: $pull_image_name"
                echo "Tagging the pulled image with original name: $original_image_name"
                docker tag "$pull_image_name" "$original_image_name"
                echo "Removing the temporary image: $pull_image_name"
                docker rmi "$pull_image_name"
            fi

            # 提取镜像名称和版本号
            image_version=$(echo "$line" | awk -F ':' '{print $2}')
            image_name=$(echo "$line" | awk -F ':' '{print $1}')

            # 构造打包文件的名称
            tar_filename=${image_name##*/}-${image_version}.tar
            echo "Saving image as: $tar_filename"

            # 将镜像保存为 tar 文件
            docker save -o "$image_dir/$tar_filename" "$original_image_name"
        else
            echo "Failed to pull image: $line"
        fi
    else
        echo "Image does not belong to registry.k8s.io. Pulling image from $line"
        # 拉取镜像
        docker pull "$line"

        # 检查镜像是否成功拉取
        if [ $? -eq 0 ]; then
            echo "Image pulled successfully: $line"
            # 提取镜像名称和版本号
            image_version=$(echo "$line" | awk -F ':' '{print $2}')
            image_name=$(echo "$line" | awk -F ':' '{print $1}')

            # 构造打包文件的名称
            tar_filename=${image_name##*/}-${image_version}.tar
            echo "Saving image as: $tar_filename"

            # 将镜像保存为 tar 文件
            docker save -o "$image_dir/$tar_filename" "$line"
        else
            echo "Failed to pull image: $line"
        fi
    fi
done < images.txt
