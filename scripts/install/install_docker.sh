#!/bin/bash
###
 # @Author: zhangliang
 # @Date: 2023-02-17 10:19:02
 # @LastEditors: zhangliang102411@126.com
 # @LastEditTime: 2024-03-04 19:01:05
 # @FilePath: \k8s-offline-setup\scripts\install_docker.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by www.jingyou.com, All Rights Reserved. 
### 

# 在 master 节点和 worker 节点都要执行

# 配置 docker damon.json
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


# 修改cri-docker 第10行内容
sudo sed -i 's|ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd://|ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd:// --pod-infra-container-image=registry.k8s.io/pause:3.9 --network-plugin=cni|g' /usr/lib/systemd/system/cri-docker.service
# 启动cri-docker
sudo systemctl daemon-reload && systemctl enable cri-docker && systemctl start cri-docker && systemctl status cri-docker