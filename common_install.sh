#!/bin/bash

PYTHON_VERSION_2="2.7.12"
PYTHON_VERSION_3="3.6.8"
REDIS_VERSION="5.0.4"
DIG_VERSION="9.11.0"


function install_init_dependence()
{
    yum install openssl openssl-devel zlib-devel gcc vim make rsync -y
}

function install_nginx ()
{
    if [ -f "/usr/sbin/nginx" ]
    then
        return 0
    fi
    yum install epel-release -y
    sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
    user=nginx
    group=nginx
    egrep "^$group" /etc/group >& /dev/null
    if [ $? -ne 0 ]
    then  
        groupadd nginx
    fi  
    
    egrep "^$user" /etc/passwd >& /dev/null  
    if [ $? -ne 0 ]
    then  
        useradd -g nginx nginx
    fi  
    yum install nginx -y
    systemctl enable nginx
}

function install_pdns ()
{
    ret=$(yum list installed|grep pdns|awk -F '[ ;]+' '{print $2}'|grep -c 4.1)
    if [ "$ret" == "2" ]
    then
        echo "pdns 4.1 already installed"
        return 0
    fi
    ret=$(yum list installed|grep pdns|awk -F '[ ;]+' '{print $2}'|grep -c 3.4)
    if [ "$ret" != "0" ]
    then
        yum remove -y pdns-backend-pipe pdns
    fi
    yum install epel-release yum-plugin-priorities -y
    sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
    curl -o /etc/yum.repos.d/powerdns-auth-41.repo https://repo.powerdns.com/repo-files/centos-auth-41.repo -k
    sed -i "s/gpgcheck=1/gpgcheck=0/g" /etc/yum.repos.d/powerdns-auth-41.repo
    yum install -y pdns pdns-backend-pipe
    sed -i "s/^ProtectSystem=full/#ProtectSystem=full/" /usr/lib/systemd/system/pdns.service
    sed -i "s/^ExecStart=\/usr\/sbin\/pdns_server.*/ExecStart=\/usr\/sbin\/pdns_server --daemon=no/" /usr/lib/systemd/system/pdns.service
    systemctl daemon-reload
    systemctl enable pdns
}

function install_dig ()
{
    if [ ! -f "/usr/bin/dig" ] || [ $(/usr/bin/dig -v 2>&1 | awk '{print $2}') != ${DIG_VERSION} ]
    then
        if [ -f "/usr/bin/dig" ]
        then
            mv /usr/bin/dig /usr/bin/dig.bak
        fi
        wget http://softrepo.hdt.qtlcdn.com/third_party/op/dig_${DIG_VERSION} -O /usr/bin/dig
        chmod +x /usr/bin/dig
    fi
}

function install_python27 ()
{
    if [ ! -f "/usr/local/bin/python" ] || [ $(/usr/local/bin/python -V 2>&1 | awk '{print $2}') != ${PYTHON_VERSION_2} ]
    then
        if [ -d "/build/python2" ]
        then
            rm -rf /build/python2
        fi
        install_init_dependence
        mkdir -p /build && cd /build && \
        curl -skL "http://softrepo.hdt.qtlcdn.com/third_party/op/Python-${PYTHON_VERSION_2}.tgz" -o python2.tgz && \
        mkdir -p /build/python2 && \
        tar -zxvf python2.tgz --strip-components=1 -C /build/python2 && \
        cd /build/python2 && \
        ./configure --prefix=/usr/local --enable-shared --enable-unicode=ucs4 LDFLAGS="-Wl,-rpath /usr/local/lib" && \
        make -j$(nproc) && \
        make altinstall && \
        curl -skL "http://softrepo.hdt.qtlcdn.com/third_party/op/get-pip.py" | /usr/local/bin/python2.7 && \
        ln -sf /usr/local/bin/python2.7 /usr/local/bin/python && \
        ln -sf /usr/local/bin/pip /usr/bin/pip && \
        /usr/bin/pip install virtualenv && \
        rm -rf /build
    fi
}

function install_python36 ()
{
    if [ ! -f "/usr/local/bin/python3.6" ] || [ $(/usr/local/bin/python3.6 -V 2>&1 | awk '{print $2}') != ${PYTHON_VERSION_3} ]
    then
        if [ -d "/build/python3" ]
        then
            rm -rf /build/python3
        fi 
        install_init_dependence
        mkdir -p /build && cd /build && \
        curl -skL "http://softrepo.hdt.qtlcdn.com/third_party/op/Python-${PYTHON_VERSION_3}.tgz" -o python3.tgz && \
        mkdir -p /build/python3 && \
        tar -zxvf python3.tgz --strip-components=1 -C /build/python3 && \
        cd /build/python3 && \
        ./configure --prefix=/usr/local --enable-shared --enable-unicode=ucs4 LDFLAGS="-Wl,-rpath /usr/local/lib" && \
        make -j$(nproc) && \
        make altinstall && \
        curl -skL "http://softrepo.hdt.qtlcdn.com/third_party/op/get-pip.py" | /usr/local/bin/python3.6 && \
        rm -rf /build
    fi
}

function install_redis5(){
    chattr -i /etc/group
    chattr -i /etc/gshadow
    chattr -i /etc/passwd
    chattr -i /etc/shadow
    if [ ! -f "/usr/local/bin/redis-server" ] || [ $(/usr/local/bin/redis-server --version | awk '{print $3}') != "v=${REDIS_VERSION}" ]
    then
        if [ -d "/build/redis-${REDIS_VERSION}" ]
        then
            rm /build/redis-${REDIS_VERSION} -rf
        fi
        mkdir -p /build && curl -skL "http://softrepo.hdt.qtlcdn.com/third_party/op/redis-${REDIS_VERSION}.tar.gz" | tar xz -C /build && \
        cd /build/redis-${REDIS_VERSION} && \
        sed -i "s/protected-mode yes/protected-mode no/" redis.conf && \
        sed -i "s/define CONFIG_DEFAULT_PROTECTED_MODE 1/define CONFIG_DEFAULT_PROTECTED_MODE 0/" src/server.h && \
        make && \
        make install && \
        rm -rf /build/redis-${REDIS_VERSION}
    fi
    groupadd redis
    useradd -g redis -d /var/redis -s /sbin/nologin redis
    mkdir -p /etc/redis
    mkdir -p /var/log/redis
    mkdir -p /var/redis/redis_6379
    chown -R redis:redis /etc/redis
    chown -R redis:redis /var/redis
    chown -R redis:redis /var/log/redis
    chattr +i /etc/group
    chattr +i /etc/gshadow
    chattr +i /etc/passwd
    chattr +i /etc/shadow
}

function install_supervisor ()
{
    if [ -f "/usr/local/bin/supervisord" ] || [ -f "/usr/bin/supervisord" ]
    then
        return 0
    fi

    if [ -f "/usr/local/bin/pip" ]
    then
cat > /usr/lib/systemd/system/supervisord.service << EOF
[Unit]
Description=supervisord - Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/bin/supervisord -c /etc/supervisord.conf
ExecReload=/usr/local/bin/supervisorctl reload
ExecStop=/usr/local/bin/supervisorctl shutdown
User=root
[Install]
WantedBy=multi-user.target
EOF
        /usr/local/bin/pip install supervisor==4.0.4 && \
        mkdir -p /etc/supervisord/conf.d && \
        wget http://softrepo.hdt.qtlcdn.com/third_party/op/supervisord.conf -O /etc/supervisord.conf && \
        systemctl daemon-reload && \
        systemctl enable supervisord
    else
        yum install epel-release -y
        yum install python-pip -y
cat > /usr/lib/systemd/system/supervisord.service << EOF
[Unit]
Description=supervisord - Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target
[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c /etc/supervisord.conf
ExecReload=/usr/bin/supervisorctl reload
ExecStop=/usr/bin/supervisorctl shutdown
User=root
[Install]
WantedBy=multi-user.target
EOF
        /usr/bin/pip install supervisor==4.0.4 && \
        mkdir -p /etc/supervisord/conf.d && \
        wget http://softrepo.hdt.qtlcdn.com/third_party/op/supervisord.conf -O /etc/supervisord.conf && \
        systemctl daemon-reload && \
        systemctl enable supervisord
    fi
}

