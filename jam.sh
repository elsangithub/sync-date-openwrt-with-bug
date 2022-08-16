#!/bin/bash
# Sync Jam otomatis berdasarkan bug isp by AlkhaNET
# Extended GMT+7 by vitoharhari
# Simplify usage and improved codes by helmiau
# Supported VPN Tunnels: OpenClash
	
dtdir="/root/date"
initd="/etc/init.d"
logp="/root/logp"
jamup2="/root/jam2_up.sh"
jamup='/root/jamup.sh'

function nyetop() {
	echo "jam.sh: Stopping VPN tunnels if available."
	logger "jam.sh: Stopping VPN tunnels if available."
	if [[ $(uci -q get openclash.config.enable) == "1" ]]; then "$initd"/openclash stop && echo "Stopping OpenClash"; fi
}

function nyetart() {
	echo "jam.sh: Restarting VPN tunnels if available."
	logger "jam.sh: Restarting VPN tunnels if available."
	if [[ $(uci -q get openclash.config.enable) == "1" ]]; then "$initd"/openclash restart && echo "Restarting OpenClash"; fi
}

function ngecurl() {
	curl -si "$cv_type" | grep Date > "$dtdir"
	echo "jam.sh: Executed $cv_type as time server."
	logger "jam.sh: Executed $cv_type as time server."
}

function sandal() {
    day=$(cat "$dtdir" | cut -b 12-13)
    month=$(cat "$dtdir" | cut -b 15-17)
    year=$(cat "$dtdir" | cut -b 19-22)
    time1=$(cat "$dtdir" | cut -b 24-25)
    time2=$(cat "$dtdir" | cut -b 26-31)
    
    case $month in
        "Jan")
           month="01"
            ;;
        "Feb")
            month="02"
            ;;
        "Mar")
            month="03"
            ;;
        "Apr")
            month="04"
            ;;
        "May")
            month="05"
            ;;
        "Jun")
            month="06"
            ;;
        "Jul")
            month="07"
            ;;
        "Aug")
            month="08"
            ;;
        "Sep")
            month="09"
            ;;
        "Oct")
            month="10"
            ;;
        "Nov")
            month="11"
            ;;
        "Dec")
            month="12"
            ;;
        *)
           continue

    esac

if [[ "$time1" == "08" ]] || [[ "$time1" == "09" ]];then
	timeif=$(echo "${time1//0/}")
	let a="$timeif""$gmt"
else
	let a="$time1""$gmt"
fi
#echo -e "time1 is $time1 and gmt is $gmt then total is $a" #debugging purpose

    case $a in
        "24")
           a="00"
            ;;
        "25")
           a="01"
            ;;
        "26")
           a="02"
            ;;
        "27")
           a="03"
            ;;
        "28")
           a="04"
            ;;
        "29")
           a="05"
            ;;
        "30")
           a="06"
            ;;
        "31")
           a="07"
            ;;
        "32")
           a="08"
            ;;
        "33")
           a="09"
            ;;
        "34")
           a="10"
            ;;
        "35")
           a="11"
            ;;
    esac

date --set "$year"."$month"."$day"-"$a""$time2"
echo -e "jam.sh: Set time to $year.$month.$day-$a$time2"
logger "jam.sh: Set time to $year.$month.$day-$a$time2"
}

if [[ "$1" == "update" ]]; then
	echo -e "jam.sh: Updating script..."
	echo -e "jam.sh: Downloading script update..."
	curl -sL raw.githubusercontent.com/vitoharhari/sync-date-openwrt-with-bug/main/jam.sh > "$jamup"
	chmod +x "$jamup"
	sed -i 's/\r$//' "$jamup"
	cat << "EOF" > "$jamup2"
#!/bin/bash
# Updater script sync jam otomatis berdasarkan bug/domain/url isp
jamsh='/usr/bin/jam.sh'
jamup='/root/jamup.sh'
[[ -e "$jamup" ]] && [[ -f "$jamsh" ]] && rm -f "$jamsh" && mv "$jamup" "$jamsh"
[[ -e "$jamup" ]] && [[ ! -f "$jamsh" ]] && mv "$jamup" "$jamsh"
echo -e 'jam.sh: Update done...'
chmod +x "$jamsh"
EOF
	sed -i 's/\r$//' "$jamup2"
	chmod +x "$jamup2"
	bash "$jamup2"
	[[ -f "$jamup2" ]] && rm -f "$jamup2" && echo -e "jam.sh: update file cleaned up!" && logger "jam.sh: update file cleaned up!"
elif [[ "$1" =~ "http://" ]]; then
	cv_type="$1"
elif [[ "$1" =~ "https://" ]]; then
	cv_type=$(echo -e "$1" | sed 's|https|http|g')
elif [[ "$1" =~ [.] ]]; then
	cv_type=http://"$1"
else
	echo -e "Usage: add domain/bug after script!."
	echo -e "jam.sh: Missing URL/Bug/Domain!. Read https://github.com/vitoharhari/sync-date-openwrt-with-bug/blob/main/README.md for details."
	logger "jam.sh: Missing URL/Bug/Domain!. Read https://github.com/vitoharhari/sync-date-openwrt-with-bug/blob/main/README.md for details."
fi

function ngepink() {
	interval="3"
	httping "$cv_type" -c "$interval" | grep connected > "$logp"
	status=$(cat "$logp" | cut -b 1-9)
  
	if [[ "$status" =~ "connected" ]]; then
		echo "jam.sh: Connection available, resuming task..."
		logger "jam.sh: Connection available, resuming task..."
	else 
		echo "jam.sh: Connection unavailable, pinging again..."
		logger "jam.sh: Connection unavailable, pinging again..."
		ngepink
	fi
}

if [[ ! -z "$cv_type" ]]; then
	nyetop
	ngepink
	ngecurl

	########
	#Start Set GMT
	if [[ "$2" =~ ^[+-][0-9]+$ ]];then
		default_gmt="$2" # custom GMT
	else
		default_gmt="+7" # default GMT+7
	fi
	gmt=$(echo -e "$default_gmt" | sed -e 's/+/+/g' -e 's/-/-/g') # optional GMT by command: script.sh api.com -7
	echo -e "jam.sh: GMT set to GMT$default_gmt"
	logger "jam.sh: GMT set to GMT$default_gmt"
	#End Set GMT
	########
	
	sandal
	nyetart

	#Cleaning files
	[[ -f "$logp" ]] && rm -f "$logp" && echo -e "jam.sh: logp cleaned up!" && logger "jam.sh: logp cleaned up!"
	[[ -f "$dtdir" ]] && rm -f "$dtdir" && echo -e "jam.sh: tmp dir cleaned up!" && logger "jam.sh: tmp dir cleaned up!"
	[[ -f "$jamup2" ]] && rm -f "$jamup2" && echo -e "jam.sh: update file cleaned up!" && logger "jam.sh: update file cleaned up!"
else
	echo -e "Usage: add domain/bug after script!."
	echo "jam.sh: Missing URL/Bug/Domain!. Read https://github.com/vitoharhari/sync-date-openwrt-with-bug/blob/main/README.md for details."
	logger "jam.sh: Missing URL/Bug/Domain!. Read https://github.com/vitoharhari/sync-date-openwrt-with-bug/blob/main/README.md for details."
fi
