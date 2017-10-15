#!/bin/sh
# 12306站点数据查询
fromDate=$(date +%F)
fromStation="IOQ"
toStation="WHN"

while [[ "${dataGetTrains:-false}" != "true" ]]; do
contentsTrains=$(curl "https://kyfw.12306.cn/otn/leftTicket/queryX?leftTicketDTO.train_date=${fromDate}&leftTicketDTO.from_station=${fromStation}&leftTicketDTO.to_station=${toStation}&purpose_codes=ADULT" \
-XGET \
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
[ -z "$length" -o "0" == "${length}"  ] && { sleep 1 ; continue ; } || dataGetTrains="true"

trainArray=$(echo "${contentsTrains}" |jq '.data.result' )
for (( i = 0; i < $length; i++ )); do
	train=$(echo "${trainArray}" | jq ".[$i]")
	trainId=""
	trainCode=""
	from=""
	to=""

	getOneTradeAllStation "${trainId}" "${from}" "${to}"
done	

done



# trainNo="6i000G10020A"
function getOneTradeAllStation()
{
	trainNo="$1"
	fromStation="$2"
	toStation="$3"

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
		-H 'X-Requested-With: XMLHttpRequest')

		length=$(echo "$contents" |sed 's/null//g'| jq '.data.data|length')
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

		    sql="insert into train_time_table_12306 ( station_name,station_no,arrive_time,start_time,train_no,stop_time) values (${station_name},${station_no},${arrive_time},${start_time},${station_train_code},${stopover_time});"
		    echo "$sql"

		done


		echo "数据获取 ${dataGet}"
	done

}


















