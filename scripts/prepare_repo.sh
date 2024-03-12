#!/bin/bash
###
 # @Author: zhangliang
 # @Date: 2023-02-17 10:19:02
 # @LastEditors: zhangliang102411@126.com
 # @LastEditTime: 2024-03-11 15:05:33
 # @FilePath: \k8s-offline-setup\scripts\install_repo.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by www.jingyou.com, All Rights Reserved. 
### 

# 在资源准备节点执行，准备yum依赖包

echo -e "-----------查看系统版本----------- \n"
echo -e "查看操作系统：$(uname -a)"

echo -e "\n-----------安裝YUM依赖----------- \n"
mkdir -p /home/repo-back
mv /etc/yum.repos.d/*.repo /home/repo-back

# 使用阿里云镜像源
curl -o /etc/yum.repos.d/CentOs-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 更新yum包
yum -y update
yum clean all && yum makecache fast


# 创建本地仓库包
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    createrepo

# 实用工具
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    yum-utils \
    nfs-utils \
    bind-utils \
    wget

# docker 依赖包
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    device-mapper-persistent-data \
    lvm2

# docker
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    docker-ce-19.03.5 \
    docker-ce-cli-19.03.5 \
    containerd.io

# 时间同步
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    chrony

# HAProxy 和 KeepAlived
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    haproxy \
    keepalived

# 配置ipvs转发 
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    ipvsadm \
    ipset \
    sysstat \
    conntrack \
    libseccomp

# 配置K8S的yum源
# google Yum源被禁用，使用Kubernetes社区YUM源
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

# kubeadm kubelet kubectl
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    kubeadm-1.29.0-150500.1.1 \
    kubelet-1.29.0-150500.1.1 \
    kubectl-1.29.0-150500.1.1

# 安装自动补全工具(可选)
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    bash-completion

# 升级系统内核
yum install --downloadonly --downloaddir=/root/k8sOfflineSetup/packages \
    perl

mv -f elrepo-release-7.0-4.el7.elrepo.noarch.rpm /root/k8sOfflineSetup/packages

# 如果之前安装过k8s 先卸载旧版本
yum remove -y kubelet kubeadm kubectl

# 安装 kubeadm kubelet kubectl
yum install -y kubeadm-1.29.0-150500.1.1  kubelet-1.29.0-150500.1.1 kubectl-1.29.0-150500.1.1
kubectl version --client
