#!/bin/bash

set -euxo pipefail

starttime=`date +'%Y-%m-%d %H:%M:%S'`


echo "                            ------------ start -------------"

wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3100.0 Safari/537.36" "https://site.ip138.com/gitee.io" -O gitee-ip-search &> /dev/null

# 匹配 ip 并去重
grep -o -E "([0-9]{1,3}\.){3}[0-9]{1,3}" gitee-ip-search | uniq > gitee-real-ip

echo "                         ----------- execute for loop ------------"

for ip in `cat gitee-real-ip`
do
wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3100.0 Safari/537.36" "https://site.ip138.com/"$ip -O $ip"-url-search" &> /dev/null
grep '"date"' $ip"-url-search" |awk -F '("/|/")' '{print $2}' > $ip"-real-url"
rm -rf $ip"-url-search"

if [[ `grep "gitee.io" $ip"-real-url" | wc -l` -eq 0 ]];then
rm $ip"-url-search" $ip"-real-url" -rf
continue
fi

for j in `cat $ip"-real-url"`
do
res=`curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3100.0 Safari/537.36" -s --head -L "https://"$j --connect-timeout 3 | grep "HTTP/" | awk '{printf $2}'`
if [[ $res -eq 200 ]]
then
echo $j >> all-real-url
fi
done

rm $ip"-real-url" -rf
done

echo "                ----------------- 第一个 for loop 结束 ------------------"

cat all-real-url | awk '!a[$0]++' > real-urls 
rm all-real-url -rf

echo "                ----------------- 第二个 for loop 开始 ------------------"
for j in `cat real-urls`
do
curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3100.0 Safari/537.36" -s -L "https://"$j -o tmp
if [[ $? -eq 0 ]]
then
title=`grep -m 1 "<title>" tmp | awk -F '</title>' '{print $1}' | awk -F '>' '{print $NF}'`
rm -rf ./tmp
if [[ "$title" = "" ]]
then
echo '  <a href="https://'$j'" target="_blank">
    <article>'$j'</article>
    </a>' >> index.html
else
echo '  <a href="https://'$j'" target="_blank">
    <article>'$title'</article>
    </a>' >> index.html
fi
else
echo '  <a href="https://'$j'" target="_blank">
    <article>'$j'</article>
    </a>' >> index.html
fi
done
echo "                           -------------- 第二个for loop 结束 -----------"

rm gitee-real-ip gitee-ip-search real-urls -rf


endtime=`date +'%Y-%m-%d %H:%M:%S'`
start_s=`date --date="$starttime" +%s`
end_s=`date --date="$endtime" +%s`

echo '本次运行时间： '`expr $end_s - $start_s`'s'
