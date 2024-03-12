#!/bin/bash
###
 # @Author: zhangliang
 # @Date: 2023-02-17 10:19:02
 # @LastEditors: zhangliang102411@126.com
 # @LastEditTime: 2024-03-04 18:27:42
 # @FilePath: \k8s-offline-setup\scripts\loadimage.sh
 # @Description: 
 # 
 # Copyright (c) 2024 by www.jingyou.com, All Rights Reserved. 
### 

# 导入镜像
# kubernetes
docker load -i ../images/kube-controller-manager-v1.26.0.tar
docker load -i ../images/kube-apiserver-v1.26.0.tar
docker load -i ../images/kube-scheduler-v1.26.0.tar
docker load -i ../images/kube-proxy-v1.26.0.tar
docker load -i ../images/coredns-v1.9.3.tar
docker load -i ../images/etcd-3.5.6-0.tar
docker load -i ../images/pause-3.9.tar

#calico 网络插件
docker load -i ../images/calico-cni-v3.25.0.tar
docker load -i ../images/calico-node-v3.25.0.tar
docker load -i ../images/calico-kube-controllers-v3.25.0.tar

# nginx ingress controller
docker load -i ../images/nginx-ingress-controller:v1.6.4.tar
docker load -i ../images/kube-webhook-certgen:v20220916-gd32f8c343.tar

# kubernetes dashboard
docker load -i ../images/dashboard:v2.7.0.tar
docker load -i ../images/metrics-scraper:v1.0.8.tar

# kuboard
docker load -i ../images/etcd-host:3.4.16-1.tar
docker load -i ../images/kuboard-agent:v3.tar
docker load -i ../images/questdb:6.0.4.tar
docker load -i ../images/kuboard-metrics-server-amd64-v0.3.6.tar