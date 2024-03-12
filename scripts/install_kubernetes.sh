#!/bin/bash

# 卸载旧版本
sudo yum remove -y kubelet kubeadm kubectl

# 安装kubelet、kubeadm、kubectl
sudo yum install -y kubeadm-1.29.0-150500.1.1  kubelet-1.29.0-150500.1.1 kubectl-1.29.0-150500.1.1
# 查看kubectl版本
sudo kubectl version --client


# 修改kubelet cgroup启动方式与docker一致
sudo sed -i 's/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"/g' /etc/sysconfig/kubelet
# 启动kubectl
sudo systemctl enable --now kubelet && systemctl status kubelet

# 安装自动补全工具(可选)
sudo yum install -y bash-completion
sudo source /usr/share/bash-completion/bash_completion
sudo echo "source <(kubectl completion bash)" >> ~/.bashrc
sudo source  ~/.bashrc   