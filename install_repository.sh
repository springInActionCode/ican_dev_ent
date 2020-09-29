#!/bin/bash
cd /etc/maven
wget http://dhlsrc.oss-cn-hangzhou.aliyuncs.com/settings.xml

mkdir /root/.m2/repository
cd /root/.m2
echo "Begin to install maven,Please waiting..."
#解压maven
wget http://dhlsrc.oss-cn-hangzhou.aliyuncs.com/repository.tar
tar -vxf  repository.tar         
echo "######################################"
echo "Begin to config environment variables,please waiting..."
echo "######################################"
#修改maven的环境变量，直接写入配置文件
 
echo "maven仓库安装成功"
