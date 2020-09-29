#!/bin/bash
 
mkdir /usr/local/idea
echo "Begin to install maven,Please waiting..."
#下载解压 
wget https://download.jetbrains.8686c.com/idea/ideaIC-2020.2.2.tar.gz
tar -vxf  ideaIC-2020.2.2.tar.gz -C /usr/local/idea      

echo "idea安装成功"
