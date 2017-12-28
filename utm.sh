#!/bin/bash
#EGAIS UTM checker
#Author - Kostya Belykh k@belykh.su

###CHANGE IT
path=//home/foo/bar
mailaddress=utm_reports@domain.ru
###

#Vars stuff
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:
port=8080
list=$path"utm_list.csv"
IFS=";"
checkdate=$(date +%Y-%m-%d\ %H:%m:%S\ %z)

#Report File recreation
rm $path"utm_output.txt"
touch $path"utm_output.txt"
echo "Subject: Отчет по УТМ" >> $path"utm_output.txt"
echo "" >> $path"utm_output.txt"
echo "Время проверки: "$checkdate >> $path"utm_output.txt"
echo "" >> $path"utm_output.txt"
while read lines
do
	set - $lines
	echo $1 >> $path"utm_output.txt"
	#Cheking UTM for availability
	STATUS=$(curl -s -o /dev/null -w '%{http_code}' $2":"$port)
	#If we get a page:
	if [ $STATUS -eq 200 ]; then
		echo $1
		curl $2":"$port > $path"tmp.html"

		cat $path"tmp.html" | grep version: | sed -e 's/<pre>//g' | tr -d '\n'  | sed 's/version:/Версия УТМ: /g' >> $path"utm_output.txt"

		pki=$(cat $path"tmp.html" | grep PKI: | sed -e 's/<pre><img src="img\/ok24.png" alt="OK">&nbsp;&nbsp;//g' \
		| sed 's#\(действителен\)\(.*\)\( по.*\)#\1\3#' | sed -e 's/<\/pre>//g')
		pkienddate=$(echo $pki | sed -E "s/^.*([-0-9\ +\:]{23}00).*$/\1/")
		pkidatediff=$((`date -d "$pkienddate" '+%s'` - `date -d "$checkdate" '+%s'`))
		let pkidatediffdays=$pkidatediff/60/60/24

		#Check PKI cert end date
		if [ $pkidatediffdays -le 21 ]; then
			echo $pki | tr -d '\n' >> $path"utm_output.txt"
			echo "ВНИМАНИЕ! До окончания PKI сертификата осталось: "$pkidatediffdays" дней" >> $path"utm_output.txt"
		else
			echo $pki | tr -d '\n' >> $path"utm_output.txt"
                        echo "До окончания PKI сертификата осталось: "$pkidatediffdays" дней" >> $path"utm_output.txt"
		fi

		gost=$(cat $path"tmp.html" | grep ГОСТ: | sed -e 's/<pre><img src="img\/ok24.png" alt="OK">&nbsp;&nbsp;//g' \
		| sed 's#\(действителен\)\(.*\)\( по.*\)#\1\3#' | sed -e 's/<\/pre>//g')
		gostenddate=$(echo $gost | sed -E "s/^.*([-0-9\ +\:]{23}00).*$/\1/")
		gostdatediff=$((`date -d "$gostenddate" '+%s'` - `date -d "$checkdate" '+%s'`))
        let gostdatediffdays=$gostdatediff/60/60/24

		#Check GOST cert end date
		if [ $gostdatediffdays -le 31 ]; then
			echo $gost | tr -d '\n' >> $path"utm_output.txt"
			echo "ВНИМАНИЕ! До окончания ГОСТ сертификата осталось: "$gostdatediffdays" дней" >> $path"utm_output.txt"
		else
			echo $gost | tr -d '\n' >> $path"utm_output.txt"
                        echo "До окончания ГОСТ сертификата осталось: "$gostdatediffdays" дней" >> $path"utm_output.txt"
		fi

		echo "" >> $path"utm_output.txt"
	#If we didn't get anything:
	else
		echo "УТМ не доступен" >> $path"utm_output.txt"
		echo "" >> $path"utm_output.txt"
	fi
done < $list
rm $path"tmp.html"
#Sending an email:
ssmtp $mailaddress < $path"utm_output.txt"
