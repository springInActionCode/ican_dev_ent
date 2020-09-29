#!/bin/bash
##下载脚本 执行脚本

wget http://dhlsrc.oss-cn-hangzhou.aliyuncs.com/MySQL_script.tar
#解压
tar -vxf MySQL_script.tar
 
# 执行

#1 创建db
mysql  -uroot -p'Dhl@isee2020' 2>/dev/null  < MySQL_script/0createdatabase.sql

#2 初始化结构
echo " 初始化结构开始"
mysql  -uroot -p'Dhl@isee2020' 2>/dev/null  < MySQL_script/1dhlgl.sql
mysql  -uroot -p'Dhl@isee2020' 2>/dev/null  < MySQL_script/3dhlgl_canbus_data.sql
echo " 初始化结构完成"

#3 初始化数据
echo " 初始化数据开始"
mysql  -uroot -p'Dhl@isee2020' 2>/dev/null  < MySQL_script/2dhlgl_data.sql
mysql  -uroot -p'Dhl@isee2020' 2>/dev/null  < MySQL_script/4dhlgl_canbus_data_data.sql
echo " 初始化数据完成"

#4 初始化存储过程
mysql  -uroot -p'Dhl@isee2020' 2>/dev/null  < MySQL_script/5dhlgl_canbus_data_function.sql

echo "DB数据初始化完成"