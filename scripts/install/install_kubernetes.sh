#!/bin/bash

# 关闭防火墙
sudo systemctl stop firewalld && systemctl disable firewalld && firewall-cmd --state
# 设置防火墙为 Iptables 并设置空规则
sudo yum -y install iptables-services && systemctl start iptables && systemctl enable
sudo iptables -F && iptables-save

# 关闭selinux
sudo setenforce 0 && sed -ri 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo sestatus

# 禁用交换分区
sudo swapoff -a && sed -ri 's/.*swap.*/#&/' /etc/fstab && free -h && grep swap /etc/fstab

# 配置时间
sudo timedatectl set-timezone Asiashanghai
sudo timedatectl set-local-rtc 0
sudo systemctl restart rsyslog
sudo systemctl restart crond

# 设置时间同步
sudo yum -y remove ntpdate
sudo yum install -y chrony 

# 时间同步配置
sudo sed -i '3s/server 0.centos.pool.ntp.org iburst/# server 0.centos.pool.ntp.org iburst/' /etc/chrony.conf  
sudo sed -i '4s/server 1.centos.pool.ntp.org iburst/# server 1.centos.pool.ntp.org iburst/' /etc/chrony.conf  
sudo sed -i '5s/server 2.centos.pool.ntp.org iburst/# server 2.centos.pool.ntp.org iburst/' /etc/chrony.conf  
sudo sed -i '6s/server 3.centos.pool.ntp.org iburst/server ntp.aliyun.com iburst/' /etc/chrony.conf

# 启动查看状态
sudo systemctl start chronyd && systemctl enable chronyd && chronyc sources && date


# 优化系统内核 配置内核路由转发及网桥过滤
sudo cat > /etc/sysctl.d/k8s.conf <<EOF
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

# 加载br_netfilter模块
sudo modprobe br_netfilter
# 查看是否加载
sudo lsmod | grep br_netfilter

# 使其生效
sudo sysctl --system


# 配置ipvs转发 
# 安装ipset及ipvsadm
sudo yum -y install ipvsadm ipset sysstat conntrack libseccomp

# 不开启 ipvs 将会使用 iptables ，但效率低，官方推荐使用ipvs内核
sudo cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
/sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
if [ $? -eq 0 ]; then
/sbin/modprobe \${kernel_module}
fi
done
EOF
sudo chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs

# 安装kubernetes
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