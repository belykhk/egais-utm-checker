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

#Пересоздаем файл с отчетом
rm $path"utm_output.txt"
touch $path"utm_output.txt"
echo "Subject: Отчет по УТМ" >> $path"utm_output.txt"
echo "" >> $path"utm_output.txt"
echo "Время проверки: "$checkdate >> $path"utm_output.txt"
echo "" >> $path"utm_output.txt"

#Читаем список из $list
while read lines
do
	set - $lines
	echo $1 >> $path"utm_output.txt"
	#Проверяем УТМ на доступность
	STATUS=$(curl -s -o /dev/null -w '%{http_code}' $2":"$port)
	#Если все хорошо и мы получаем страницу
	if [ $STATUS -eq 200 ]; then
		echo $1
		curl $2":"$port > $path"tmp.html"

		#Получаем версию УТМ
		utm_ver=$(cat $path"tmp.html" | grep "<p>Версия" | head -n 1 | sed -e 's/<p>//g' | sed -e 's/<\/p>//g' | tr -d '\n' \
		| sed 's/Версия/Версия УТМ:/g' | sed 's/://g')
		echo -e $utm_ver >> $path"utm_output.txt"

		#Работаем по следующему варианту, если у нас версия УТМ 2.0.*
		if [[ $utm_ver == *"2.0"* ]]; then

			#Получаем информацию о PKI сертификате
			pki=$(cat $path"tmp.html" | grep PKI: | sed -e 's/<pre><img src="img\/ok24.png" alt="OK">&nbsp;&nbsp;//g' \
			| sed 's#\(действителен\)\(.*\)\( по.*\)#\1\3#' | sed -e 's/<\/pre>//g')
			echo -e $pki  >> $path"utm_output.txt"

			pkienddate=$(echo $pki | sed -E "s/^.*([-0-9\ +\:]{23}00).*$/\1/")
			pkidatediff=$((`date -d "$pkienddate" '+%s'` - `date -d "$checkdate" '+%s'`))
			let pkidatediffdays=$pkidatediff/60/60/24

			#Проверка. Не осталось ли сертификату PKI меньше чем N дней.
			if [ $pkidatediffdays -le 21 ]; then
				echo -e "ВНИМАНИЕ! До окончания PKI сертификата осталось: "$pkidatediffdays" дней" >> $path"utm_output.txt"
			else
				echo -e "До окончания PKI сертификата осталось: "$pkidatediffdays" дней" >> $path"utm_output.txt"
			fi

			#Получаем информацию о ГОСТ сертификате
			gost=$(cat $path"tmp.html" | grep ГОСТ: | sed -e 's/<pre><img src="img\/ok24.png" alt="OK">&nbsp;&nbsp;//g' \
			| sed 's#\(действителен\)\(.*\)\( по.*\)#\1\3#' | sed -e 's/<\/pre>//g')
			echo -e $gost >> $path"utm_output.txt"

			gostenddate=$(echo $gost | sed -E "s/^.*([-0-9\ +\:]{23}00).*$/\1/")
			gostdatediff=$((`date -d "$gostenddate" '+%s'` - `date -d "$checkdate" '+%s'`))
			let gostdatediffdays=$gostdatediff/60/60/24

			#Проверка. Не осталось ли сертификату ГОСТ меньше чем N дней.
			if [ $gostdatediffdays -le 31 ]; then
				echo -e "ВНИМАНИЕ! До окончания ГОСТ сертификата осталось: "$gostdatediffdays" дней" >> $path"utm_output.txt"
			else
				echo -e "До окончания ГОСТ сертификата осталось: "$gostdatediffdays" дней" >> $path"utm_output.txt"
			fi

		fi

		#Работаем по следующему варианту, если у нас версия УТМ 2.1.*
		if [[ $utm_ver == *"2.1"* ]]; then

			#Получаем информацию о PKI сертификате
			pki=$(cat $path"tmp.html" | grep "Сертификат RSA" | sed 's#\(Действителен\)\(.*\)\( по.*\)#\1\3#' \
			| cut -d ">" -f7 | sed -e 's/<\/div//g')
			echo -e "PKI: "$pki  >> $path"utm_output.txt"

			pkienddate=$(echo $pki | sed -E "s/^.*([-0-9\ +\:]{23}00).*$/\1/")
			pkidatediff=$((`date -d "$pkienddate" '+%s'` - `date -d "$checkdate" '+%s'`))
			let pkidatediffdays=$pkidatediff/60/60/24

			#Проверка. Не осталось ли сертификату PKI меньше чем N дней.
			if [ $pkidatediffdays -le 21 ]; then
				echo -e "ВНИМАНИЕ! До окончания PKI сертификата осталось: "$pkidatediffdays" дней" >> $path"utm_output.txt"
			else
				echo -e "До окончания PKI сертификата осталось: "$pkidatediffdays" дней" >> $path"utm_output.txt"
			fi

			#Получаем информацию о ГОСТ сертификате
			gost=$(cat $path"tmp.html" | grep "Сертификат ГОСТ" | sed 's#\(Действителен\)\(.*\)\( по.*\)#\1\3#' \
			| cut -d ">" -f7 | sed -e 's/<\/div//g')
			echo -e "ГОСТ: "$gost >> $path"utm_output.txt"

			gostenddate=$(echo $gost | sed -E "s/^.*([-0-9\ +\:]{23}00).*$/\1/")
			gostdatediff=$((`date -d "$gostenddate" '+%s'` - `date -d "$checkdate" '+%s'`))
			let gostdatediffdays=$gostdatediff/60/60/24

			#Проверка. Не осталось ли сертификату ГОСТ меньше чем N дней.
			if [ $gostdatediffdays -le 31 ]; then
				echo -e "ВНИМАНИЕ! До окончания ГОСТ сертификата осталось: "$gostdatediffdays" дней" >> $path"utm_output.txt"
			else
				echo -e "До окончания ГОСТ сертификата осталось: "$gostdatediffdays" дней" >> $path"utm_output.txt"
			fi

		fi
		echo "" >> $path"utm_output.txt"
	#Если мы вместо http\200 получаем что-то другое (например 404 или 503)
	else
		echo "УТМ не доступен" >> $path"utm_output.txt"
		echo "" >> $path"utm_output.txt"
	fi
done < $list
rm $path"tmp.html"
ssmtp $mailaddress < $path"utm_output.txt"
