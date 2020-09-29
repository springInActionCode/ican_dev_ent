#!/bin/bash
#导入环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin:~/bin
export PATH

MYSQL_VERSION="5.7.29"
YUM_REPO="http://mirrors.e6.e6gpshk.com/centos/7/download/e6yun.repo"
MYSQL_COMP=("mysql-community-server.x86_64" "mysql-community-client.x86_64" "mysql-community-devel.x86_64")

function check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用 sudo -i来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}

function check_installed(){ 
    CHECK_EXIST=`rpm -qa | grep mariadb`  
    if [ -z "$CHECK_EXIST" ]
    then
        echo "没有安装mariadb！"
    else
        echo "存在mariadb,开始卸载..."
        rpm -e --nodeps $CHECK_EXIST
        if [ $? -eq 0 ]
        then
            echo "${CHECK_EXIST}已卸载完成！"
        else
            echo "${CHECK_EXIST}卸载失败，请检查！"
            exit 1
        fi
    fi
}

function import_yum_repo(){
    if [ -e "/etc/yum.repos.d/e6yun.repo" ]
    then
        echo "yum源已导入，无需重复操作！"
    else
        echo "开始导入yum源..."
        wget -O  /etc/yum.repos.d/e6yun.repo $YUM_REPO $1
        if [ $? -eq 0 ]
        then 
            echo "yum源导入成功！"
        else
            echo "yum源导入失败！"
            exit 1
        fi
        echo "yum源导入成功！"
        yum clean all
    fi
}

function install_db(){
    CHECK_EXIST=`yum list installed|grep mysql`
    echo $CHECK_EXIST
    if [ -z "$CHECK_EXIST" ]
    then  
        echo "开始安装MySQL相关组件(server,devel,client)..."
        for cpn in ${MYSQL_COMP[@]}
        do
            yum -y install $cpn
            if [ $? -eq 0 ]
            then
                echo "${cpn}已安装成功！"
            else
                echo "${cpn}安装失败，请检查！"
                exit 1
            fi
        done
    else
        echo -e "已安装MySQL组件:\n${CHECK_EXIST}"
    fi

}


function config_security(){
    CHECK_EXEC=`grep "Plugin 'validate_password' is disabled" /var/log/mysqld.log`
    if [ -z "$CHECK_EXEC" ]
    then 
        start_db
        echo "开始运行安全设置向导..."
        DB_PASSWD=`grep 'A temporary password' /var/log/mysqld.log|awk '{print $(11)'}`
        echo "MySQL初始密码为：${DB_PASSWD}"
        mysql_secure_installation
        if [ $? -eq 0 ]
            then
                echo "安全设置向导已完成！"
        else
            echo "安全设置向导执行失败，请检查！"
            exit 1
        fi
        stop_db
    else
        echo "安全设置向导已运行，无需重复操作！"
    fi
}

function config_mycnf(){
    if [ -z `grep 'port=3306' /etc/my.cnf` ] 
    then
        echo "开始配置参数文件..."
        mv /etc/my.cnf /etc/my.cnf_bak  

        echo "[client]
        port=3306
        socket=/var/lib/mysql/mysql.sock
        [mysqld]
        port = 3306
        user=mysql
        datadir=/var/lib/mysql
        log-error=/var/log/mysqld.log
        pid-file=/var/run/mysqld/mysqld.pid
        socket=/var/lib/mysql/mysql.sock
        explicit_defaults_for_timestamp
        slow_query_log=ON #开启慢查询日志
        slow_query_log_file=/var/lib/mysql/slow.log
        long_query_time=1

        innodb_file_per_table=1 #独立表空间
        innodb_file_format=barracuda #压缩表
        innodb_flush_log_at_trx_commit=2 #提交方式

        max_allowed_packet = 300M #接受的数据包大小用户mysqldump导入数据
        character-set-server=utf8mb4
        collation-server=utf8mb4_general_ci
        event_scheduler=on
        lower_case_table_names=1
        innodb_large_prefix=1
        max_connections =1000
        max_connect_errors =1000

        server-id=1 #每台机器不重复 
        log_bin=mysql-bin   #bin日志路径
        expire_logs_days=30  #日志保存时间">/etc/my.cnf
        
        if [ $? -eq 0 ]
        then
             sed -i 's/        //g' /etc/my.cnf
             echo "修改配置文件完成！"
        else
            echo "修改配置文件执行失败，请检查！"
            exit 1
        fi
    else
        echo "配置文件已修改，无需重复操作！"
    fi
}

function config_firewall(){
    CHECK_EXIST=`firewall-cmd --list-ports`
    if [ -z "$CHECK_EXIST" ]
    then
        echo -e "防火墙已关闭，请手动增加规则\nfirewall-cmd --zone=public --add-port=3306/tcp --permanent\n并通过netstat -lntp检查所有需要添加的端口，完成后启动防火墙\nsystemctl start firewalld"        
    else
        echo "开始配置防火墙..."
        if [ -e "/etc/firewalld/zones/public.xml" ]
        then
            firewall-cmd --zone=public --add-port=3306/tcp --permanent
            firewall-cmd --reload
            echo "防火墙配置完成"
        fi       
    fi
}

function move_dataurl(){
    
    read -p "是否需要更换数据文件路径[Y/N]:" num
    case $num in
    Y | y)
        read -p "请输入需要移动的数据文件路径:" url
        stop_db
        echo "更改路径:$url属主为mysql"
        chown -R mysql:mysql $url
        echo "移动数据文件至:$url"
        cd /var/lib/mysql
        cp -a * $url
        if [ $? -eq 0 ]
        then
            echo "删除/var/lib/mysql下的数据文件"
            rm /var/lib/mysql -rf
        else
            echo "/var/lib/mysql下的数据文件删除失败，请检查!"
            exit 1
        fi
        echo "建立/var/lib/mysql与$url的软链接"
        cd /var/lib
        ln -s $url mysql
        if [ $? -eq 0 ]
        then
            echo "移动数据文件已完成!"
        else
            echo "/var/lib/mysql与$url的软链接建立失败，请检查!"
            exit 1
        fi
        start_db
    ;;
    N | n)
        echo "无需移动数据文件路径！"
    ;;
    *)
     echo "输入错误"
    ;;
    esac
    echo "MySQL安装及配置已完成！！！"
}

function start_db(){
    if [ -z "`ps -ef|grep mysqld|grep -v "grep"`" ]
    then 
        echo '启动MySQL数据库...'
        systemctl start mysqld
        if [ $? -eq 0 ]
        then
            echo 'MySQL数据库已成功启动！'
        else
            echo "MySQL数据库启动失败，请检查！"
            exit 1
        fi
    else
        echo "MySQL数据库已启动，无需重复操作！"
    fi
}

function stop_db(){
    if [ -z "`ps -ef|grep mysqld|grep -v "grep"`" ]
    then 
        echo 'MySQL数据库没有启动！'
    else
        echo '正在停止MySQL数据库...'
        systemctl stop mysqld
        if [ $? -eq 0 ]
        then
            echo 'MySQL数据库已停止！'
        fi
    fi
}

function restart_db(){
    echo '重启MySQL数据库...'
    systemctl restart mysqld
    if [ $? -eq 0 ]
    then
        echo 'MySQL数据库已重启！'
    fi
}

function uninstall_db(){
    echo '正在删除MySQL数据库...'
    yum erase mysql*
    if [ $? -eq 0 ]
    then
        echo 'MySQL数据库已删除！'
    fi
    rm -f /etc/my.cnf*
    rm -f /var/log/mysql*
}

echo "Centos7 MySQL 5.7.29一键安装脚本(默认3306)"
echo -e "1) 安装MySQL\n2) 启动MySQL\n3) 停止MySQL\n4) 重启MySQL\n" 
read -p "请输入选项:" num
case $num in
	1)
		check_root 
		check_installed && \
		import_yum_repo && \
		install_db && \
		config_security && \
		config_mycnf && \
		config_firewall && \
		start_db
	;;
	2)
		start_db
	;;
	3)
		stop_db
	;;
	4) 	restart_db
	;;
	5)
		exit
	;;
	*) 
		echo "输入错误"
esac
