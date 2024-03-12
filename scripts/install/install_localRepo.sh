#!/bin/bash

# 卸载旧版本
sudo yum remove -y ntpdate
sudo yum remove -y docker*
sudo yum remove -y kubelet kubeadm kubectl
# 安裝新依賴
sudo yum localinstall -y ../../packages/*.rpm

sudo createrepo  /root/k8sOfflineSetup/packages

# 备份现有源
sudo if [ -f "/etc/yum.repos.d/CentOs-Base.repo" ];then
    mkdir -p /home/repo-back
    mv /etc/yum.repos.d/*.repo /home/repo-back
fi
sudo cp -f ../../repos/CentOS-Media.repo /etc/yum.repos.d/

# 更新yum包
sudo yum -y update
sudo yum clean all && yum makecache fast