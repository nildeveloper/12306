#!/bin/sh
# 12306站点数据查询
# https://kyfw.12306.cn/otn/resources/js/framework/station_name.js
# 
# 


# trainNo="6i000G10020A"
function getOneTradeAllStation()
{
	local i=0
	local trainNo="$1"
	local fromStation="$2"
	local toStation="$3"
	local dataGet="false"
	local length=0
	# echo "获取 ${trainNo}"
	while [[ "${dataGet:-false}" != "true" ]]; do
		contents=$(curl "https://kyfw.12306.cn/otn/czxx/queryByTrainNo?train_no=${trainNo}&from_station_telecode=${fromStation}&to_station_telecode=${toStation}&depart_date=${fromDate}" \
		-XGET -s \
		-H 'Referer: https://kyfw.12306.cn/otn/leftTicket/init' \
		-H 'Host: kyfw.12306.cn' \
		-H 'Pragma: no-cache' \
		-H 'Accept: */*' \
		-H 'Connection: keep-alive' \
		-H 'Accept-Encoding: gzip, deflate' \
		-H 'Accept-Language: zh-cn' \
		-H 'DNT: 1' \
		-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38' \
		-H 'If-Modified-Since: 0' \
		-H 'Cache-Control: no-cache' \
		-H 'X-Requested-With: XMLHttpRequest' --compressed)

		length=$(echo "$contents" | sed 's/null//g'| jq '.data.data|length')
		
		[ -z "$length" -o "0" == "${length}"  ] && { sleep 1 ; continue ; } || dataGet="true"

		for (( i = 0; i < $length; i++ )); do

			timeTable=$(echo "${contents}" | jq ".data.data|.[${i}]")

			station_name=$(echo "${timeTable}" | jq '.station_name')
			arrive_time=$(echo "${timeTable}" | jq '.arrive_time')
			station_no=$(echo "${timeTable}" | jq '.station_no')
			stopover_time=$(echo "${timeTable}" | jq '.stopover_time')
			start_time=$(echo "${timeTable}" | jq '.start_time')

			[ -z "$station_train_code" ] && station_train_code=$(echo "${timeTable}" | jq '.station_train_code')
			end_station_name=$(echo "${timeTable}" | jq '.end_station_name')

		    sql="insert ignore into train_time_table_12306 ( station_name,station_no,arrive_time,start_time,train_no,stop_time) values (${station_name},${station_no},${arrive_time},${start_time},${station_train_code},${stopover_time});"
		    
		    echo "${station_no} ${station_name}"

		    echo "$sql" | mysql --login-path=local sns -N -f 

		done
		echo "数据获取 ${dataGet}"
	done
	
}

#
#
#
function getFromStationToStationTrainList()
{

fromDate="$1"
fromStation="$2"
toStation="$3"
while [[ "${dataGetTrains:-false}" != "true" ]]; do
contentsTrains=$(curl "https://kyfw.12306.cn/otn/leftTicket/query?leftTicketDTO.train_date=${fromDate}&leftTicketDTO.from_station=${fromStation}&leftTicketDTO.to_station=${toStation}&purpose_codes=ADULT" \
-X GET -s \
-H 'Referer: https://kyfw.12306.cn/otn/leftTicket/init' \
-H 'Host: kyfw.12306.cn' \
-H 'Pragma: no-cache' \
-H 'Accept: */*' \
-H 'Connection: keep-alive' \
-H 'Accept-Encoding: gzip, deflate' \
-H 'Accept-Language: zh-cn' \
-H 'DNT: 1' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Safari/604.1.38' \
-H 'If-Modified-Since: 0' \
-H 'Cache-Control: no-cache' \
-H 'X-Requested-With: XMLHttpRequest'  --compressed)

length=$(echo "$contentsTrains" |sed 's/null//g'| jq '.data.result|length')
# echo "获取火车列表: ${length}"
if [[ $length -eq 0 ]]; then
 	echo "获取失败结果是： ${contentsTrains}"
fi 
[ -z "$length" -o "0" == "${length}"  ] && { sleep 1 ; continue ; } || dataGetTrains="true"

trainArray=$(echo "${contentsTrains}" |jq '.data.result' )
length=$(echo "${trainArray}" | jq 'length')
# echo "trainArray : ${trainArray} ${length}"
for (( i = 0 ; i < $length ; i++ )); do
	echo "i = $i"
	train=$(echo "${trainArray}" | jq ".[$i]")
	# echo "train: ${train}"
	trainId=$(echo "${train}"| awk -F '|' '{print $3}')
	trainCode=$(echo "${train}"| awk -F '|' '{print $4}')
	firstStation=$(echo "${train}"| awk -F '|' '{print $5}')
	lastStation=$(echo "${train}"| awk -F '|' '{print $6}')
	fromStation=$(echo "${train}"| awk -F '|' '{print $7}')
	toStation=$(echo "${train}"| awk -F '|' '{print $8}')

	echo "列车编号: ${trainCode}  出发站: ${fromStation}  到达站:${toStation}  (第一站: ${firstStation} 终点站:${lastStation})"
	getOneTradeAllStation "${trainId}" "${fromStation}" "${toStation}" && sleep 1
	echo "${length}  $i"
done	

done

	


}




main()
{
	local fromDate=$(date -r $(expr $(date '+%s') + 86400)  +%F)
	local fromCity="$1"
	local toCity="$2"
	local sql2GetFromStation="select code from station_12306 where name like '${fromCity}%' ORDER BY LENGTH(name) desc limit 1 "
	local sql2GetToStation="select code from station_12306 where name like '${toCity}%' ORDER BY LENGTH(name) desc limit 1 "

	local fromStation=$(echo "${sql2GetFromStation}" | mysql --login-path=local sns -N -f)
	local toStation=$(echo "${sql2GetToStation}" | mysql --login-path=local sns -N -f)

	echo "正在处理 从${fromCity}(${fromStation}) 到 ${toCity}(${toStation})的车次查询  "
	if [ "${fromStation}" == "" -o "${toStation}" == "" ]; then
		echo "没找到该城市的站点"
		return
	fi

	getFromStationToStationTrainList "${fromDate}"  "${fromStation}" "${toStation}"

}

main "$@"
#main "武汉" "深圳北"
















