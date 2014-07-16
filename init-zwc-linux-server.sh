#!/bin/bash
#This scrip is for Web Server's initialization.
#Written by Jinzhao.Meng on 26th,June,2014
TMP_DIR=/tmp
NFS=10.71.64.28

function host_yum_nfs
{
    IP_ADDR=$(ifconfig|grep 10.71|awk -F':' '{print $2}'|awk -F' ' '{print $1}') 
    HOST_PRE=$(echo $IP_ADDR|awk -F "." '{print $3"."$4}')
    HOSTNAME=$HOST_PRE.web.gzqxg.inzwc.com
    hostname $HOSTNAME
    sed -i "s/localhost.localdomain/$HOSTNAME/g" /etc/sysconfig/network

# Change yum configuration
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    wget ftp://10.71.64.108/yum/yum_source6.inzwc.com.repo -O /etc/yum.repos.d/yum_source6.inzwc.com.repo
    yum makecache

# NFS Mount
    chkconfig rpcbind on
    mkdir /nfs
    mount -o nolock,vers=3 $NFS:/data0/nfs /nfs
#if you want mount NFS from /etc/fstab,use follow command
#echo "10.71.64.28:/data0/nfs    /nfs    nfs    rw,nolock,noatime,nodiratime,rsize=8192,wsize=8192,vers=3,soft,intr 0 0" >> /etc/fatab
#but sometimes it may not work,so I use the second command and add it to /etc/rc.d/rc.local
    echo "mount -o nolock,vers=3 $NFS:/data0/nfs /nfs" >> /etc/rc.d/rc.local
}

# Cleanaccounts and other script created by sina
function clean_sina
{
    echo "清除sina相关初始项"
    rm -f /var/spool/cron/sysmon
    sed -i -e '/cfagent/d'  -e '/sina/d' -e '/cfexecd/d'    -e '/cfengine/d' /etc/crontab
    ps -ef|grep -E 'cfexecd|cfagent|cfengine'|grep -v grep|awk '{print $2}'|xargs kill -9
    mv /var/cfengine /var/cfengine_sina
    mv /usr/local/cfengine/ /usr/local/cfengine_sina
#
    ps -ef|grep watchagent|grep -v grep|awk '{print $2}'|xargs kill -9
    rm -f /etc/rc*/*watchagent* /etc/init.d/*watchagent*
    mv /usr/local/sinawatch_agent/ /usr/local/sinawatch_agent_sina
#yum
    rm -f /etc/yum.repos.d/sinawatch-agent.repo
    rm -f /etc/sinayum.conf
#ssh
    if [-f "/etc/rc.d/rc3.d/S18sshd"]
    then
	rm -f /etc/rc.d/rc3.d/S18sshd
	sed -i '/sshd/d' /etc/rc.d/rc.local
    fi
#sina users
    chattr -i  /etc/passwd /etc/shadow
    for user in bangjian chengsong chenyang douyin duanchao dulei genlei guochao3 guoliang9 hangang jianfei1 junhai kaijun1 kaiwei3 leilei3 libin1 liuchang1 liukai liyuan maqian pengjie qingming rdsup_api ruoyu shixi_chencheng shukui1 tengfei4 tianyu wangshuo wangxu4 wb_guorui wb_liukai wb_zhuoyue xianbo xianhui xiaodong2 xiaofeng6 xiaoyue1 yuli3 yunfei zhaiyu
    do
        usermod -L $user
        usermod -s /bin/false $user
        sed -i "/$user/d" /etc/sudoers
    done
}

#Add users and groups
function add_user_group
{
    chattr -i /etc/passwd /etc/shadow
    groupadd www -g 600
    adduser www -u 600 -g www
    groupadd mfs -g 601
    useradd mfs -u 601 -g mfs
    groupadd mqadmin -g 602
    useradd mqadmin -u 602 -g mqadmin
    groupadd mysql -g 603
    useradd mysql -u 603 -g mysql
    groupadd zabbix -g 604
    useradd zabbix -u 604 -g zabbix
    groupadd zwcwatch -g 700
    useradd zwcwatch -u 700 -g zwcwatch 
    groupadd xujing -g 712
    adduser xujing -u 712 -g xujing
    chattr +i  /etc/passwd /etc/shadow

#Set www user ssh keys
    mkdir /usr/home/www/.ssh
    chmod 700 /usr/home/www/.ssh
    cat /nfs/id_rsa.pub >> /usr/home/www/.ssh/authorized_keys
    chmod 600 /usr/home/www/.ssh/authorized_keys
    chown -R www:www /usr/home/www/.ssh
}



#Disable selinux,ipv6 and iptables
function disables
{
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
#Disable IPv6
    echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
    echo "IPV6INIT=no" >> /etc/sysconfig/network
#Disable iptalbes    
    chkconfig iptables off
    service iptables stop
}


#Kernel boot parameter
function kernel_para
{
	#The following command will turn off Advanced Power Management
    sed -i 's/rhgb/apm=off/g' /boot/grub/menu.lst
	#disable acpi and change I/O algorithm to deadline
    sed -i 's/quiet/acpi=off\ elevator=deadline/g' /boot/grub/menu.lst

	#Optimize kernel running parameter
    mv /etc/sysctl.conf /etc/sysctl.conf.bak

cat << EOF > /etc/sysctl.conf
kernel.pid_max = 1000000
net.ipv4.conf.all.accept_redirects = 0 
net.ipv4.conf.default.accept_redirects = 0 
net.ipv4.conf.all.send_redirects = 0 
net.ipv4.conf.default.send_redirects = 0 
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2

net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.ip_local_port_range = 1024 65535

net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default = 2097152
net.core.wmem_default = 2097152
net.ipv4.tcp_window_scaling=1

net.core.netdev_max_backlog = 10000
net.core.somaxconn = 262144

net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

net.ipv4.tcp_orphan_retries = 1
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_max_orphans = 8192
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.ip_forward = 0
net.ipv4.tcp_max_tw_buckets = 50000
net.ipv4.tcp_no_metrics_save=1

net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_mem = 50576   64768   98152
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_timestamps = 0

#net.nf_conntrack_max = 655360 
#net.netfilter.nf_conntrack_tcp_timeout_established = 180
#net.netfilter.nf_conntrack_max=6553600
#net.netfilter.nf_conntrack_tcp_timeout_time_wait=120
#net.netfilter.nf_conntrack_tcp_timeout_close_wait=60
#net.netfilter.nf_conntrack_tcp_timeout_fin_wait=120

net.ipv4.neigh.default.gc_thresh1=10240
net.ipv4.neigh.default.gc_thresh2=40960
net.ipv4.neigh.default.gc_thresh3=81920

vm.swappiness=10
fs.file-max = 1000000
EOF

sysctl -p
}

function system_set
{
    #Rsyslogd
    echo "*.*    @10.71.64.29" >> /etc/rsyslog.conf
    /etc/init.d/rsyslog reload


    #Ntpdate
    yum install ntp -y
    sed -i '/ntpdate/d' /var/spool/cron/root
    echo "1 * * * * /usr/sbin/ntpdate tiger.sina.com.cn >/dev/null" >> /var/spool/cron/root


    #File description
    echo "*		soft    nofile  80240" >> /etc/security/limits.conf
    echo "*         hard    nofile  80240" >> /etc/security/limits.conf

    sed -i 's/1024/80240/g' /etc/security/limits.d/90-nproc.conf
    echo "root       soft    nproc     unlimited" >> /etc/security/limits.d/90-nproc.conf
    echo "*          hard    nproc     802400" >> /etc/security/limits.d/90-nproc.conf

	#Make suer that the system is running on level 3
	sed -i 's/id:5/id:3/g' /etc/inittab

	#decrease the number of system tty to 2
	sed -i 's/1-6/1-2/g' /etc/init/start-ttys.conf

}

function pkg_install
{
    #add epel source
    rpm -ivh /nfs/pkg/epel-release-6-8.noarch.rpm

    #MFS installation 
    echo "===================安装mfs====================="
    yum -y install fuse-devel fuse zlib-devel
    tar -zxf /nfs/pkg/mfs-1.6.27-1.tar.gz
    cd mfs-1.6.27
    ./configure --prefix=/usr/local/mfs --with-default-user=mfs --with-default-group=mfs --enable-mfsmount --disable-mfsmaster --disable-mfschunkserver
    make
    make install

    mkdir /mfs
    /usr/local/mfs/bin/mfsmount /mfs -H 10.71.64.253 -S /forall
    echo "/usr/local/mfs/bin/mfsmount /mfs -H 10.71.64.253 -S /forall" >> /etc/rc.d/rc.local
    echo ""
	#Zabbix installation
    echo "===================安装zabbix===================="
	#install sysstat for zabbix I/O monitor
    yum install sysstat -y
	#install zbbix
    tar -zxf /nfs/pkg/zabbix-2.0.3.tar.gz
    cd zabbix-2.0.3
    ./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix --enable-agent
    make 
    make install

	#configuration
    cp -rf /nfs/zabbix_template/* /etc/zabbix/
    chown -R zabbix.zabbix /etc/zabbix/
    sed -i "s/Hostname=/Hostname=$IP_ADDR/g" /etc/zabbix/zabbix_agentd.conf

    chmod 640 /etc/sudoers

cat << EOF >> /etc/sudoers
Cmnd_Alias SU = /bin/su -
Cmnd_Alias SUWWW = /bin/su - www 
xujing    ALL=(root)      NOPASSWD: SU,SUWWW,SERVICES
Cmnd_Alias FILESOCKET =   /etc/zabbix/scripts/zabbix_fileSocket_cron.sh,/etc/zabbix/scripts/zabbix_tomcat_cron.sh,/etc/zabbix/scripts/file_socket.sh,/usr/bin/sudo,/bin/su,/bin/kill
zabbix    ALL=(root)      NOPASSWD: FILESOCKET
EOF
	chmod 600 /etc/sudoers

	cp /nfs/script/zabbix_agentd /etc/init.d/
	chmod +x /etc/init.d/zabbix_agentd
	chkconfig --add zabbix_agentd
	chkconfig zabbix_agentd on
	/etc/init.d/zabbix_agentd start

#run zabbix on crontab
cat <<EOF > /var/spool/cron/zabbix
# run zabbix data gathering for custom checks every min
*/3 * * * * /usr/bin/sudo /etc/zabbix/scripts/zabbix_tomcat_cron.sh > /dev/null 2>&1
* * * * * /etc/zabbix/scripts/zabbix_vmstat_cron.sh > /dev/null 2>&1
* * * * * /etc/zabbix/scripts/zabbix_iostat_cron.sh > /dev/null 2>&1
* * * * * /etc/zabbix/scripts/zabbix_tcpConStat_cron.sh > /dev/null 2>&1
* * * * * /usr/bin/sudo /etc/zabbix/scripts/zabbix_fileSocket_cron.sh > /dev/null 2>&1
* * * * * /etc/zabbix/scripts/zabbix_DbConnStat_cron.sh > /dev/null 2>&1
EOF
echo ""

	#Puppet installation
	echo "====================安装puppet================"
	#add puppet source
	rpm -ivh /nfs/pkg/puppetlabs-release-6-7.noarch.rpm 
	yum install puppet -y

	echo "server=215.salt.kvm74.gzqxg.inzwc.com" >> /etc/puppet/puppet.conf
	echo "listen=true" >> /etc/puppet/puppet.conf
	echo "$IP_ADDR   $HOSTNAME" >> /etc/hosts
	/usr/bin/puppet agent --test
	echo "*/10 * * * * /usr/bin/puppet agent --test > /dev/null 2>&1" >> /var/spool/cron/root
	echo ""

	#Salt installation
	echo "====================安装salt=================="
	echo "10.71.64.215    215.salt.kvm74.gzqxg.inzwc.com" >> /etc/hosts
	yum -y install zeromq3 zeromq3-devel salt-minion

	#Please note that there is a blank( ) between colon(:) and the parameter behind it.
	#For example,there is a blank between "master" and "215".
	echo "master: 215.salt.kvm74.gzqxg.inzwc.com" >> /etc/salt/minion
	echo "id: $HOSTNAME"  >> /etc/salt/minion
	/etc/init.d/salt-minion restart
	echo ""
	#JDK installation
	#add java environment to /etc/profile
	echo "====================安装JDK1.7================"
cat << EOF >> /etc/profile
export JAVA_HOME=/usr/java/default 
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/lib:$JAVA_HOME/jre/bin:$PATH:$HOME/bin:$PATH
export JAVA_TOOLS=$JAVA_HOME/lib/tools.jar
EOF
	source /etc/profile
	#install jdk
	tar -zxf /nfs/pkg/jdk-7u15-linux-x64.tar.gz -C /usr/java
	cd /usr/java
	chown -R root:root jdk1.7.0_15
	rm -f latest
	ln -s /usr/java/jdk1.7.0_15 latest
	java -version
	echo ""

	#Apr and apr-util installation
	echo "====================安装apr==================="
	cd $TMPDIR
	tar -zxf /nfs/pkg/apr-1.4.5.tar.gz
	cd apr-1.4.5/
	./configure --prefix=/usr/local/apr
	make
	make install
	echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/apr/lib" >> /etc/profile

	cd $TMPDIR
	tar -zxf /nfs/pkg/apr-util-1.3.10.tar.gz
	cd apr-util-1.3.10/
	./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
	make
	make install
	echo ""
	#Cronolog installation
	echo "====================安装cronolog=============="
	cd $TMPDIR
	tar -zxf /nfs/pkg/cronolog-1.6.2.tar.gz 
	cd cronolog-1.6.2
	./configure
	make
	make install
	echo ""

	#zwcserver installation
	echo "====================安装zwcserver=============="
	cd /usr/local/
	tar -zxf /nfs/pkg/zwcserver.tar.gz
	echo "*/3 * * * * /usr/local/zwcserver/bin/tomcat_log_send.sh > /dev/null 2>&1" >> /var/spool/cron/root
	echo ""
}

#Other scripts and configuration
function dir_and_profile
{
	#Create applications' running directories,/data0/opt is for tomcat program and /data0/www is for webapps.
	echo "创建/data0/opt及/data0/www目录"
	mkdir -p /data0/opt
	chown -R www.www /data0/opt
	mkdir -p /data0/www
	chown -R www.www /data0/www
	ln -s /mfs/ShareFile/upload /data0/www/upload
	mkdir /script
	rsync -av /nfs/script/57/ /script
	hmod +x -R /script

	echo "alias vi=vim" >> /etc/profile
	echo 'export PS1="\[\e]0;\a\]\n\[\e[1;32m\]\[\e[1;33m\]\H\[\e[1;35m\]<\$(date +\"%Y-%m-%d %T\")> \[\e[32m\]\w\[\e[0m\]\n\u>\\$ "' >> /etc/profile
	source /etc/profile
}

function main
{
	host_yum_nfs
	clean_sina
	add_user_group
	disables
	kernel_para
	system_set
	pkg_install
	dir_and_profile
}
echo "***************欢迎对系统进行安全初始化设置***************"
echo "1.修改主机名、yum配置，挂载NFS"
echo "2.清除sina相关用户及设置"
echo "3.添加新用户"
echo "4.禁用selinux、ipv6及iptables"
echo "5.优化内核启动及运行参数"
echo "6.系统日志、时间、文件打开数等设置"
echo "7.安装相关软件包"
echo "8.创建/data0目录及PS1设置"
echo "9.一键初始化所有设置"
echo "**********************************************************"
echo "请输入你要选择的操作:"

read INPUT
case "$INPUT" in
        1 )
		host_yum_nfs
        ;;
        2 )
		clean_sina
        ;;
        3 )
		add_user_group
        ;;
        4 )
		disables
        ;;
        5 )
		kernel_para
        ;;
        6 )
		system_set
        ;;
        7 )
		pkg_install
        ;;
        8 )
		dir_and_profile
        ;;
        9 )
		main
        ;;
        * )
        echo "请输入正确的选项"
        exit
        ;;
esac

