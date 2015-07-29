#!/bin/bash
#
# 通过对比 ping 响应时间，找到本机最快的上传ip
# Travis@fir.im
#

function refresh_host()
{
  IP="$1"
  UPLOAD_HOST="upload.qiniu.com"
  TARGET_PATH="/etc/hosts"
  TEMP_PATH=".temp_hosts"
  echo "`sed '/upload.qiniu.com/d' $TARGET_PATH`" > $TEMP_PATH 
  echo "${IP}   ${UPLOAD_HOST}" >> $TEMP_PATH
  #
  echo "允许使用sudo，自动帮你更新host"
  echo  -e "\n#### 你也可以用任意文本编辑器打开 \033[1;91m/etc/hosts\033[0m 在文件中加一行(如果已经设置，只需要改掉IP就可以了):\n\n\t${FINAL_IP} upload.qiniu.com\n"
  sudo mv ${TEMP_PATH} ${TARGET_PATH}
}

echo "本脚本基于 http://t.cn/RLC7jc9 "
echo -e '\n本脚本解决部分地区七牛上传速度慢的问题，只用于本机，\e[1;91m请勿用于生产环境\e[0m，有使用问题请联系 tw@fir.im (我相信你肯定没有问题的)\n\n'
echo '#### 获取最快的服务器IP ...'

# 从 17ce.com 抓的七牛上传IP列表
ips="upload.qiniu.com
61.54.219.52
61.140.14.19
60.222.221.45
60.211.209.209
58.51.150.50
58.242.249.28
58.220.6.152
222.243.110.59
221.238.24.101
221.206.120.62
221.202.204.58
219.154.65.182
219.145.172.16
218.92.221.211
218.61.193.156
218.5.238.218
210.66.47.19
180.97.211.36
175.43.120.13
163.177.171.209
14.215.9.88
123.138.60.8
123.133.75.68
122.143.27.13
119.84.111.85
117.169.17.3
116.55.236.53
115.231.182.136
113.5.251.205
113.17.140.183
111.202.69.163
111.11.31.36
106.39.255.186
106.38.227.6
106.38.227.5
101.71.89.200"

for ip in $ips
do
    # 只 ping 一次
    P=`ping -c 1 $ip | grep "icmp"`

    # 读取 IP 和 延迟
    read IP T<<< $( echo ${P} |  awk '{split($0,a,/[ |=|:]/); print a[4]" "a[11]}')
    TIME=${T%%.*}


    # 没有ping通，忽略
    if [[ -z "$TIME" ]] ; then

      # 防止本地不通，给个默认值
      if [[ -z "$LOCAL_TIME" ]] ; then
        LOCAL_TIME=1000
        PING_TIME=1000
      fi

      continue
    fi

    # 本地的数值
    if [[ -z "$FINAL_IP" ]] ; then
      LOCAL_IP=$IP
      FINAL_IP=$IP

      LOCAL_TIME=$TIME
      PING_TIME=$TIME

      continue
    fi

    # 对比用时并得到更快的IP
    if (( ${TIME} < ${PING_TIME} )) ; then
      PING_TIME=$TIME
      FINAL_IP=$IP

      echo -e "\t✓ 找到更快的IP：$IP , 延迟：$PING_TIME 毫秒"
    fi


done

if [ "${LOCAL_IP}" == "${FINAL_IP}" ] ; then
  echo  -e "\n✓ 本地IP($LOCAL_IP) 已经是最快的了（只有 \033[1;91m${LOCAL_TIME}\033[0m 毫秒），如果还感觉不够快，请自检人品 :)"
else
  refresh_host "${FINAL_IP}"
  echo  -e "#### 打完收工，去 \033[4;31mfir.im\033[0m 重新上传应用感受一下速度吧 :)\n"
fi
