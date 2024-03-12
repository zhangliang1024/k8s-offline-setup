#!/bin/bash
###
 # @Author: zhangliang
 # @Date: 2023-02-17 10:19:02
 # @LastEditors: zhangliang102411@126.com
 # @LastEditTime: 2024-03-11 13:46:32
 # @FilePath: \k8s-offline-setup\scripts\install_base.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by www.jingyou.com, All Rights Reserved. 
### 

# 在 master 节点和 worker 节点都要执行

# -------------------------基础环境准备-------------------------

# 查看系统版本
echo -e "-----------查看系统版本----------- \n"
echo -e "操作系统：$(uname -a)"
echo -e "操作系统版本：$(cat /etc/redhat-release)"
echo -e "系统内核版本：$(uname -r)"


echo -e "-----------份YUM源仓库----------- \n"
mkdir -p /home/repo-back
mv /etc/yum.repos.d/*.repo /home/repo-back
curl -o /etc/yum.repos.d/CentOs-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo


echo -e "-----------升级系统内核----------- \n"
## 升级系统内核
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


echo -e "-----------更新yum包缓存----------- \n"
# 更新yum包
yum -y update
yum clean all && yum makecache fast


echo -e "-----------安装基础工具包----------- \n"
# 基础工具包
yum install -y wget jq psmisc vim net-tools telnet yum-utils device-mapper-persistent-data lvm2 git lrzsz conntrack-tools libseccomp libtool-ltdl


echo -e "-----------设置系统文件句柄----------- \n"
# 设置系统文件句柄
cat <<EOF >> /etc/security/limits.conf
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* soft memlock unlimited
* hard memlock unlimited
EOF


echo -e "-----------配置系统日志持久化---------- \n"
# 配置持久化
systemctl status systemd-journald
mkdir /var/log/journal
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

echo -e "-----------重启服务器---------- \n"
# 所有节点配置完内核后，重启服务器，保证重启后内核生效。
reboot -h now

# -------------------------基础环境准备-------------------------