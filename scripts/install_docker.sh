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

# 安装 docker
# 参考文档如下
# https://docs.docker.com/install/linux/docker-ce/centos/ 
# https://docs.docker.com/install/linux/linux-postinstall/

# 卸载旧版本
sudo yum remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

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
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo docker version && docker info|grep systemd


# 关闭 防火墙
sudo systemctl stop firewalld && systemctl disable firewalld && firewall-cmd --state
# 设置防火墙为 Iptables 并设置空规则
sudo yum -y install iptables-services && systemctl start iptables && systemctl enable
sudo iptables -F && iptables-save


# 关闭 SeLinux
sudo setenforce 0 && sed -ri 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo sestatus

# 关闭 swap
sudo swapoff -a && sed -ri 's/.*swap.*/#&/' /etc/fstab && free -h && grep swap /etc/fstab

# 优化系统内核 配置内核路由转发及网桥过滤
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
fs.may_detach_mounts = 1
vm.overcommit_memory=1
vm.swappiness=0
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720

net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 131072
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF

# 使其生效
sysctl --system