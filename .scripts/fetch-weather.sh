#!/bin/bash

## Collect data
cache_dir="$HOME/.cache/eww/weather"
cache_weather_stat=${cache_dir}/weather-stat
cache_weather_degree=${cache_dir}/weather-degree
cache_weather_hex=${cache_dir}/weather-hex
cache_weather_icon=${cache_dir}/weather-icon
cache_weather_updatetime=${cache_dir}/weather-updatetime

if [[ -z "$OPENWEATHER_API_KEY" ]]; then
	echo "Please set the OPENWEATHER_API_KEY environment variable."
	exit 1
fi
if [[ -z "$OPENWEATHER_LAT" ]]; then
	echo "Please set the OPENWEATHER_LAT environment variable."
	exit 1
fi
if [[ -z "$OPENWEATHER_LON" ]]; then
	echo "Please set the OPENWEATHER_LON environment variable."
	exit 1
fi

## Weather data
KEY=$OPENWEATHER_API_KEY
LAT=$OPENWEATHER_LAT
LON=$OPENWEATHER_LON
UNITS=metric

## Make cache dir
if [[ ! -d "$cache_dir" ]]; then
	mkdir -p ${cache_dir}
fi

## Get data
get_weather_data() {
	weather=`curl -sf "http://api.openweathermap.org/data/3.0/onecall?lat=${LAT}&lon=${LON}&exclude=minutely,hourly,daily&appid=${KEY}&units=${UNITS}"`
	echo ${weather} >&2
	weather=$(echo "$weather" | jq -r ".current")

	if [ ! -z "$weather" ]; then
		weather_temp=`echo "$weather" | jq ".temp" | cut -d "." -f 1`
		weather_icon_code=`echo "$weather" | jq -r ".weather[].icon" | head -1`
		weather_description=`echo "$weather" | jq -r ".weather[].description" | head -1 | sed -e "s/\b\(.\)/\u\1/g"`

		#Big long if statement of doom
		if [ "$weather_icon_code" == "50d"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "50n"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "01d"  ]; then
			weather_icon=" "
			weather_hex="#e0af68"
		elif [ "$weather_icon_code" == "01n"  ]; then
			weather_icon=" "
			weather_hex="#c0caf5"
		elif [ "$weather_icon_code" == "02d"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "02n"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "03d"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "03n"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "04d"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "04n"  ]; then
			weather_icon=" "
			weather_hex="#7aa2f7"
		elif [ "$weather_icon_code" == "09d"  ]; then
			weather_icon=""
			weather_hex="#7dcfff"
		elif [ "$weather_icon_code" == "09n"  ]; then
			weather_icon=""
			weather_hex="#7dcfff"
		elif [ "$weather_icon_code" == "10d"  ]; then
			weather_icon=""
			weather_hex="#7dcfff"
		elif [ "$weather_icon_code" == "10n"  ]; then
			weather_icon=""
			weather_hex="#7dcfff"
		elif [ "$weather_icon_code" == "11d"  ]; then
			weather_icon=""
			weather_hex="#ff9e64"
		elif [ "$weather_icon_code" == "11n"  ]; then
			weather_icon=""
			weather_hex="#ff9e64"
		elif [ "$weather_icon_code" == "13d"  ]; then
			weather_icon=" "
			weather_hex="#c0caf5"
		elif [ "$weather_icon_code" == "13n"  ]; then
			weather_icon=" "
			weather_hex="#c0caf5"
		elif [ "$weather_icon_code" == "40d"  ]; then
			weather_icon=" "
			weather_hex="#7dcfff"
		elif [ "$weather_icon_code" == "40n"  ]; then
			weather_icon=" "
			weather_hex="#7dcfff"
		else
			weather_icon=" "
			weather_hex="#c0caf5"
		fi
		echo "$weather_icon" >  ${cache_weather_icon}
		echo "$weather_description" > ${cache_weather_stat}
		echo "$weather_temp""°C" > ${cache_weather_degree}
		echo "$weather_hex" > ${cache_weather_hex}
		date "+%Y-%m-%d %H:%M:%S" | tee ${cache_weather_updatetime} >/dev/null
	else
		echo "Weather Unavailable" > ${cache_weather_stat}
		echo " " > ${cache_weather_icon}
		echo "-" > ${cache_weather_degree}
		echo "#adadff" > ${cache_weather_hex}
		date "+%Y-%m-%d %H:%M:%S" | tee ${cache_weather_updatetime} >/dev/null
	fi
}

check_network() {
	local max=12
	local cnt=0

	while [ $cnt -lt $max ]; do
        if ping -c1 8.8.8.8 &>/dev/null || ping -c1 1.1.1.1 &>/dev/null; then
            return 0
        fi
        echo "Waiting for network connection... (attempt: $((cnt + 1))/$max)" >&2
        sleep 5
        ((cnt++))
    done

	echo "Network connection failed after $max attempts." >&2
	return 1
}

## Execute
if [[ -z "$1" ]]; then
	if check_network; then
		get_weather_data
	fi
elif [[ "$1" == "--icon" ]]; then
	cat ${cache_weather_icon}
elif [[ "$1" == "--temp" ]]; then
	cat ${cache_weather_degree}
elif [[ "$1" == "--hex" ]]; then
	tail -F ${cache_weather_hex}
elif [[ "$1" == "--stat" ]]; then
	cat ${cache_weather_stat}
elif [[ "$1" == "--updatetime" ]]; then
	cat ${cache_weather_updatetime}
fi