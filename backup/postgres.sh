
#!/bin/bash
#
# This script is used to install ELK STACK
#Elasticsearch requires Java 8 or later. Use the official Oracle distribution or an open-source distribution such as OpenJDK.
MYDOMAIN='mp.tl'

#Verify Root
verify_root() {
    # Verify running as root:
    if [ "$(id -u)" != "0" ]; then
       echo "This script must be run as root" 1>&2
       exit 1
    fi
  }

#Update system packages
update_system_packages() {
  apt-get -y update
}

#check if java installed
check_java()
  clear
  echo -n "checking if java is installed \n"
  echo "-----------------------------------------"
  dpkg --get-selections | grep -q java
      if [ $? -eq 1 ] ; then
        #install java 
        echo "Installing Java 8"
        install_java_packages()
        #Elasticsearch requires Java 8 or later
        elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]]
        then
            apt-get update && apt-get install -y oracle-java8-installer 
      fi
  }


#Install Java
install_java_packages() {
  apt-get install -y python-software-properties software-properties-common apt-transport-https
  add-apt-repository ppa:webupd8team/java -y
  #Elasticsearch requires Java 8 or later
  apt-get update && apt-get install -y oracle-java8-installer
  }


#Install and Configure Elasticsearch
install_elasticsearch() {
  #import PGP key  
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
  #update apt sources list
  echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list
  sudo apt-get update && sudo apt-get install -y elasticsearch
  #Elasticsearch is not started automatically after installation 
          if [ command -v systemctl >/dev/null ] ; then
               systemctl daemon-reload
               systemctl enable elasticsearch.service
          else
               update-rc.d elasticsearch defaults 95 10
               service elasticsearch start
          fi
          }

configure_elastixsearch() {
  conf_elastixsearch='elasticsearch.yml'
  conf_elastixsearch_default ='/etc/default/elasticsearch'
  conf_elastixsearch_svc ='/usr/lib/systemd/system/elasticsearch.service'
  cd /etc/elasticsearch/
  #bootstrap.memory_lock: true
  sed -i '/bootstrap.memory_lock:/s/^#//g' $conf_elastixsearch
  #network.host: localhost
  sed -i '/network.host:/s/^#//g' $conf_elastixsearch
  #http.port: 9200
  sed -i '/http.port:/s/^#//g' $conf_elastixsearch
  #LimitMEMLOCK=infinity
  sed -i '/LimitMEMLOCK=/s/^#//g' $conf_elastixsearch_svc
  #MAX_LOCKED_MEMORY=unlimited
  sed -i '/MAX_LOCKED_MEMORY=/s/^#//g' $conf_elastixsearch_default
  #start service 
  service elasticsearch start
  #check if service is running
  netstat -plntu | grep [0-9]:${1:-9200} -q ; 
    if [ $? -eq 1 ] ; then 
      echo "Elasticserach service is running"
    else 
      echo "Elasticserach Server is stopped - please check your installation"
    fi
    exit 1
  #test
  curl -XGET 'localhost:9200/_nodes?filter_path=**.mlockall&pretty'
  curl -XGET 'localhost:9200/?pretty'
}



#Install and Configure Kibana with Apache2
install_kibana() {
  conf_kibana='/etc/kibana/kibana.yml'
  cd /etc/kibana
  #install package
  apt-get install -y kibana
  #enable kibana
  update-rc.d kibana defaults
  #server.port: 5601
  sed -i '/server.port:/s/^#//g' $conf_kibana
  # server.host: "localhost"
  sed -i '/server.host:/s/^#//g' $conf_kibana
  #elasticsearch.url: "http://localhost:9200"
  sed -i '/elasticsearch.url:/s/^#//g' $conf_kibana
  #start kibana
  update-rc.d kibana defaults 96 9
  service kibana start
  #enable Kibana mod proxy 
  a2enmod proxy
  a2enmod proxy_http
  #check if port is active
  check_port_kibana()
  }

check_port_kibana() {
 netstat -ntpl | grep [0-9]:${1:-5601} -q ; 
    if [ $? -eq 1 ] ; then 
      echo "Kibana service is running"
    else 
      echo "Kibana Server is stopped - please check your installation"
    fi
    exit 1
}


#Create apache config file for kibana
#please edit ServerName and ServerAdmin 
configure_kibana() {
  cd /etc/apache2/sites-available
  #create file
  touch  kibana.conf
  #insert config
  cat << EOF > kibana.conf
  <VirtualHost *:80>
  ServerName kibana.$MYDOMAIN
  ServerAdmin admin@$MYDOMAIN
    # Reverse Proxy
    ProxyRequests Off
    ProxyPass / http://127.0.0.1:5601
    ProxyPassReverse / http://127.0.0.1:5601
    RewriteEngine on
    RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
    RewriteRule .* http://127.0.0.1:5601%{REQUEST_URI} [P,QSA]
    ErrorLog ${APACHE_LOG_DIR}/kibana_error.log
    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/kibana_access.log combined
    </VirtualHost> 
    EOF

#enable apache config file
    a2ensite kibana.conf
    service apache2 reload
}

#Install and Configure Logstash
install_logstash() {
    #install pacjage
    apt-get install -y logstash
    #create config file
    touch /etc/logstash/conf.d/logstash.conf
    cd /etc/logstash/conf.d/
    #start logstash
    initctl start logstash
    #install geolocation data for maps 
    cd /etc/logstash
    curl -O "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz"
    gunzip GeoLite2-City.mmdb.gz
}

verify_root()
update_system_packages()
check_java()
install_elasticsearch()
configure_elastixsearch()
install_kibana()
configure_kibana()
install_logstash()





