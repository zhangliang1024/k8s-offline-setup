#!/bin/bash
###
 # @Author: zhangliang
 # @Date: 2023-02-17 10:19:02
 # @LastEditors: zhangliang102411@126.com
 # @LastEditTime: 2024-03-11 14:14:16
 # @FilePath: \k8s-offline-setup\scripts\prepare\sys_init.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by www.jingyou.com, All Rights Reserved. 
### 

# 在资源准备节点执行，准备基础环境

# 查看系统版本
echo -e "-----------查看系统版本----------- \n"
echo -e "查看操作系统：$(uname -a)"
echo -e "操作系统版本：$(cat /etc/redhat-release)"
echo -e "系统内核版本：$(uname -r)"

echo -e "\n-----------升级系统内核----------- \n"
# 升级系统内核
yum -y install perl
# 导入elrepo gpg key
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
# 安装elrepo YUM源仓库
yum install -y https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
# 安装kernel-ml版本，ml为长期稳定版本，lt为长期维护版本
yum --enablerepo="elrepo-kernel" install -y kernel-ml.x86_64
# 设置grub2默认引导为0
grub2-set-default 0
# 重新生成grub2引导文件
grub2-mkconfig -o /boot/grub2/grub.cfg


echo -e "\n-----------文件句柄优化----------- "
# 文件句柄优化
cat <<EOF >> /etc/security/limits.conf
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* soft memlock unlimited
* hard memlock unlimited
EOF

echo -e "\n--------配置系统日志持久化-------- \n"
# 配置系统日志持久化
systemctl status systemd-journald
mkdir -p /var/log/journal
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
# 持久化保存到磁盘
Storage=persistent
# 压缩历史日志
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
# 最大占用空间 10G
SystemMaxUse=10G
# 单日志文件最大 200M
SystemMaxFileSize=200M
# 日志保存时间 2周
MaxRetentionSec=2week
# 不将日志转发到 syslog
ForwardToSyslog=no
EOF
systemctl restart systemd-journald

reboot -h now
