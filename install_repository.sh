#!/bin/bash
 
wget http://project-oss.oss-cn-shenzhen.aliyuncs.com/dhlgl/settings.xml
mv settings.xml /etc/maven     
mkdir /root/.m2

echo "Begin to install maven,Please waiting..."
#解压
wget http://project-oss.oss-cn-shenzhen.aliyuncs.com/dhlgl/repository.tar
tar -vxf repository.tar  -C /root/.m2
  
echo "maven仓库安装成功"
