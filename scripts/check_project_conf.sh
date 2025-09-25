#!/bin/bash
# SUBMISSION MUST UNPACK TO project
FOLDER="project"
TMP_FOLDER="tmp"
TEST_FOLDER="test"
LOG="log.txt"

##### CHECK SUBMISSION FILE EXIST
if [ -z "$1" ]; then
	PROJECT_TARFILE="project.tgz"
else
	PROJECT_TARFILE=$1
fi
if [ ! -f $PROJECT_TARFILE ] ; then
  echo "ERROR: $PROJECT_TARFILE does not exist!"
  exit 1
fi
CURRENT=`pwd`
##### WARNING OF FOLDER DELETING
  echo "##### The script will delete two folders below from your current directory:"
  echo "- $TMP_FOLDER"
  echo "- $TEST_FOLDER"
  read -n 1 -s -r -p "##### Press q to terminate or other key to proceed " INPUT
  if [ "$INPUT" == "q" ]; then
    echo -e "\n"
    exit 1
  fi
  echo -e "\n\n"
##### CREATE TMP_FOLDER FOR EXTRACTED FILES
if [ -d $TEST_FOLDER ] ; then
  rm -fR $TEST_FOLDER
fi
if [ -d $TMP_FOLDER ] ; then
  rm -fR $TMP_FOLDER
fi
mkdir $TMP_FOLDER
cd $TMP_FOLDER
ERR=0
##### CHECK STUDENT TARBALL
echo "##### unpack $PROJECT_TARFILE"
##### check tgz extract to correct folder name
  tar -tf ../$PROJECT_TARFILE > TMP
  #echo "##### $PROJECT_TARFILE"
  F=`head -1 TMP`
  ISFOLDER=`head -1 TMP | grep '\/$' | wc -l`

  if [ $ISFOLDER -eq 0 ]; then
    # EXTRACT TO FILES
    mkdir $FOLDER
    tar zxf ../$PROJECT_TARFILE -C $FOLDER
    echo "ERROR: submission does not unpack to \"$FOLDER\""
    echo "ERROR: submission does not unpack to \"$FOLDER\"" >> ${FOLDER}/${LOG}
    ERR=$(($ERR + 1))
  elif [ "${FOLDER}/" != "${F}" ]; then
    # EXTRACT TO WRONG FOLDER
    F=`echo $F | cut -d "/" -f 1`
    tar zxf ../$PROJECT_TARFILE
    mv $F $FOLDER
    echo "ERROR: wrong folder name \"$F\" instead of \"$FOLDER\""
    echo "ERROR: wrong folder name \"$F\" instead of \"$FOLDER\"" >> ${FOLDER}/${LOG}
    ERR=$(($ERR + 1))
  else
    # EXTRACT TO CORRECT FOLDER
    tar zxf ../$PROJECT_TARFILE
    echo "OK: $PROJECT_TARFILE unpack to $FOLDER"
    echo "OK: $FILE unpack to $FOLDER" >> ${FOLDER}/${LOG}
  fi

##### check valid ASN in the extracted project folder
  if [ -f ${FOLDER}/ASN ] ; then
    ASN=`head -1 ${FOLDER}/ASN | cut -d " " -f 1`
    if [ $ASN -ge 100 ] && [ $ASN -le 200 ]; then
      echo "ASN: $ASN"
      #echo "OK: ASN: $ASN" >> ${FOLDER}/${LOG}
      mv $FOLDER $ASN
    else
      echo "ERROR: $ASN is not within the range of assigned numbers"
      echo "ERROR: $ASN is not within the range of assigned numbers" >> ${FOLDER}/${LOG}
      ERR=$(($ERR + 1))
    fi
  else
    echo "ERROR: ASN file is missing"
    echo "ERROR: ASN file is missing" >> ${FOLDER}/${LOG}
    ERR=$(($ERR + 1))
  fi
##### remove folder with wrong ASN
if [ -d $FOLDER ] ; then
  rm -fR $FOLDER
fi
rm TMP
cd $CURRENT
#echo "----- unpack submissions completed."
##### CHECK STUDENT TARBALL - COMPLETED
#echo "-----"
#echo "##########"
if [ $ERR -gt 0 ] ; then
  rm -fR $TMP_FOLDER
  echo "##### UNPACK FAIL"
  echo "Your file will not be accepted for the verification test"
  echo "Make sure to fix the error shown above and rerun the script again!"
else
  echo "##### UNPACK OK"
  echo "No error when extracting the \"$PROJECT_TARFILE\" folder"
#  echo "The content is temporarily extracted to ./TMP/${ASN}"
#  echo "Now, run the basic test with the command below:"
#  echo "./100_verification.sh"
  echo "The script will proceed with a basic test."
  echo "It will also delete a folder below if it exists on your current directory:"
  echo "- $ASN"
  echo ""
  echo "NOTE: The basic test is a small subset of the verfication test."
  echo "In particular, it only checks lab.conf and devices configurations."
  echo "Passing the basic test does not mean you will pass the verification test."
  echo "#####"
  read -n 1 -s -r -p "Press any key to continue"
  echo -e "\n\n"
fi

echo "##### BEGIN CHECKING CONFIGURATIONS"
#RESULTS="results.txt"
#TEST_FOLDER="test"
if [ -d $TEST_FOLDER ] ; then
  rm -fR $TEST_FOLDER
fi
#mv ${TMP_FOLDER}/${ASN} $TEST_FOLDER
#rmdir ${TMP_FOLDER}
cd ${TMP_FOLDER}
mv ${ASN} $TEST_FOLDER
mv $TEST_FOLDER ..
cd $CURRENT
if [ -d $TMP_FOLDER ] ; then
  rm -fR $TMP_FOLDER
fi
#cp -a ${TMP_FOLDER}/${ASN} $TEST_FOLDER

  ##### CHECK KATHARA CONFIG 
ERR=0
PENALTY=0
IPPENALTY=0
DNSPENALTY=0
WWWPENALTY=0
DHCPPENALTY=0
BGPPENALTY=0
STATICPENALTY=0

cd $TEST_FOLDER
##### BEGIN: COUNT INTERFACE ON LAB.CONF
echo "### CHECK lab.conf"
if [ -f "CONF_LABCONF" ] ; then
        rm CONF_LABCONF
fi
echo "# CONF_LABCONF" >> $LOG
# get all active physical interfaces of ASX
grep as${ASN} lab.conf | sed '/^#/d' | sed '/image/d' > TMP
echo "# number of interfaces used in Kathara configuration"
echo -e " DEVICE\t#INT"
ERROR=0
ROUTER=(r1 r2 r3 r4)
for i in ${ROUTER[@]}
do
  echo $i >> $LOG
  POINT=0
  COUNT=`grep as${ASN}${i} TMP | wc -l`
  if [ $COUNT -lt 3 ] ; then
     ERROR=1
     ERR=$(( $ERR + 1))
  else
    POINT=1
  fi
  echo -e " $i\t$COUNT"
  echo "$i $COUNT $POINT" >> CONF_LABCONF
done
if [ $ERROR -eq 1 ] ; then
  echo "ERROR: lab.conf has a router with no redundant path"
  echo "ERROR: lab.conf has a router with no redundant path" >> $LOG
  exit 1
fi

ERROR=0
SERVER=(s1 s2 s3)
for i in ${SERVER[@]}
do
  echo $i >> $LOG
  POINT=0
  COUNT=`grep as${ASN}${i} TMP | wc -l`
  if [ $COUNT -gt 1 ] ; then
    ERROR=1
    ERR=$(( $ERR + 1))
  else
    POINT=1
  fi
  echo -e " $i\t$COUNT"
  echo "$i $COUNT $POINT" >> CONF_LABCONF
done
if [ $ERROR -eq 1 ] ; then
  echo "ERROR: lab.conf has a server with more than one interface"
  echo "ERROR: lab.conf has a server with more than one interface" >> $LOG
  exit 1
fi
S1=`sed -n 5p CONF_LABCONF | cut -d " " -f 2`
S2=`sed -n 6p CONF_LABCONF | cut -d " " -f 2`
S3=`sed -n 7p CONF_LABCONF | cut -d " " -f 2`
if [ $S1 -eq 0 ] ; then
  echo "ERROR: lab.conf s1 interface is not connected"
  echo "ERROR: lab.conf s1 interface is not connected" >> $LOG
  exit 1
fi
SUM=$(( $S1 + $S2 + $S3 ))
if [ $SUM -le 1 ] ; then
  echo "ERROR: lab.conf you must use more server apart from s1"
  echo "ERROR: lab.conf you must use more server apart from s1" >> $LOG
  exit 1
fi

ERROR=0
CLIENT=(c1 c2)
for i in ${CLIENT[@]}
do
  echo $i >> $LOG
  POINT=0
  COUNT=`grep as${ASN}${i} TMP | wc -l`
  if [ $COUNT -gt 1 ] ; then
    ERROR=1
    ERR=$(( $ERR + 1))
  else
    POINT=1
  fi
  echo -e " $i\t$COUNT"
  echo "$i $COUNT $POINT" >> CONF_LABCONF
done
if [ $ERROR -eq 1 ] ; then
  echo "ERROR: lab.conf has a client with more than one interface"
  echo "ERROR: lab.conf has a client with more than one interface" >> $LOG
  exit 1
fi
C1=`sed -n 8p CONF_LABCONF | cut -d " " -f 2`
C2=`sed -n 9p CONF_LABCONF | cut -d " " -f 2`
SUM=$(( $C1 + $C2 ))
if [ $SUM -eq 0 ] ; then
  echo "ERROR: lab.conf you must use at least one client"
  echo "ERROR: lab.conf you must use at least one client" >> $LOG
  exit 1
fi
##### END: COUNT INTERFACE ON LAB.CONF

###### BEGIN: GET DEVICE INTERFACE IP ADDRESS
if [ -f "CONF_IP" ] ; then
        rm CONF_IP
fi
echo "### GET IP address configurations"
ROUTER=(r1 r2 r3 r4)
for i in ${ROUTER[@]}
do
	#echo $i >> CONF_IP
        if [ -f "${i}" ] ; then
                rm $i
        fi
        echo "# as${ASN}${i}"
        #grep -e inter -e "ip add" as${ASN}${i}/etc/frr/frr.conf | sed 's/^[ \t]*//' | sed 's/ip //' > TMP
	sed 's/^[ \t]*//' as${ASN}${i}/etc/frr/frr.conf | grep -e "^inter" -e "^ip add" | sed 's/ip //' > TMP

        ### remove unused interface and duplication IP address
        LI=1
        LA=2
        TOTAL=`cat TMP | wc -l`
        while [ $LA -le $TOTAL ]
        do
                I=`sed -n ${LI}p TMP | grep interface | wc -l`
                A=`sed -n ${LA}p TMP | grep address | wc -l`
                if [ $I -eq 1 ] ; then
                        if [ $A -eq 1 ] ; then
                                LI=$(($LI + 2))
                                LA=$(($LA + 2))
                        else
				# remove I as it has no IP address
                                sed -i "${LI}d" TMP
                        fi
                else
                        # suspect duplicate address
			# keep the first address and delete the rest
                        X=`sed -n ${LI}p TMP | cut -d " " -f 2`
                        LX=$(($LI - 1))
                        Y=`sed -n ${LX}p TMP | cut -d " " -f 2`
                        LZ=$(($LI - 2))
                        Z=`sed -n ${LZ}p TMP | cut -d " " -f 2`
                        echo "$i $Z $Y $X" >> DUP
                        sed -i "${LI}d" TMP
                fi
                TOTAL=`cat TMP | wc -l`
        done

	# if last row is an interface without an IP address, then we remove it
        LAST=`tail -1 TMP | grep interface | wc -l`
        if [ $LAST -eq 1 ]; then
                sed -i '$ d' TMP
        fi
	# iterate through the interface/ip pair
        TOTAL=`cat TMP | wc -l`
        LINE=2
        while [ $LINE -le $TOTAL ]
        do
                LN=$(($LINE - 1))
                INTERFACE=`sed -n ${LN}p TMP | cut -d " " -f 2`
                IP=`sed -n ${LINE}p TMP | cut -d " " -f 2`
                #IP=`sed -n ${LINE}p TMP | cut -d " " -f 2 | cut -d "/" -f 1`
                echo -e " $INTERFACE\t$IP"
                echo "$INTERFACE $IP" >> $i
                echo "$i $INTERFACE $IP" >> CONF_IP
                LINE=$(($LINE + 2))
        done
done

# check eth0 IP addresses on r1 and r2
R1=`grep eth0 r1 | cut -d " " -f2`
R2=`grep eth0 r2 | cut -d " " -f2`
if [ "$R1" != "1.0.0.5/31" ] ; then
        echo "ERROR: r1 eth0 must be 1.0.0.5/31"
        echo "ERROR: r1 eth0 must be 1.0.0.5/31" >> $LOG
        exit 1
fi
echo "1 r1 eth0" > CONF_IP_POINTS
if [ "$R2" != "2.21.0.1/31" ] ; then
        echo "ERROR: r2 eth0 must be 2.21.0.1/31"
        echo "ERROR: r2 eth0 must be 2.21.0.1/31" >> $LOG
        exit 1
fi
echo "1 r2 eth0" >> CONF_IP_POINTS

# check IP addresses are from your assigned IP address block
ROUTER=(r1 r2 r3 r4)
for i in ${ROUTER[@]}
do
        #echo $i
	if [ "$i" == "r1" ] || [ "$i" == "r2" ]; then
          sed '/eth0/d' $i > TMP
	fi
        TOTAL=`cat TMP | wc -l`
        L=1
        while [ $TOTAL -gt 0 ] && [ $L -le $TOTAL ] ;
        do
                IF=`sed -n ${L}p TMP | cut -d " " -f 1`
                FIRST=`sed -n ${L}p TMP | cut -d " " -f 2 | cut -d "." -f 1`
                SECOND=`sed -n ${L}p TMP | cut -d " " -f 2 | cut -d "." -f 2`
                #echo $IF $FIRST $SECOND
                if [ $FIRST -ne 1 ] && [ $SECOND -ne $ASN ] ; then
                        echo "ERROR: $i ${IF} has wrong address: ${FIRST}.${SECOND}.x.x"
                        echo "ERROR: $i ${IF} has wrong address: ${FIRST}.${SECOND}.x.x" >> $LOG
			IPPENALTY=$(( $IPPENALTY + 1 ))
                        #exit 1
                fi
                L=$(( $L + 1 ))
        done
done
echo "1 routers" >> CONF_IP_POINTS

SERVER=(s1 s2 s3)
for i in ${SERVER[@]}
do
        echo $i >> $LOG
        if [ -f "${i}" ] ; then
                rm $i
        fi
        echo "# as${ASN}${i}" 
        sed -i '/^#/d' as${ASN}${i}.startup
        sed -i '/^$/d' as${ASN}${i}.startup
        INT=`grep -o '[^ ]*eth[^ ]*' as${ASN}${i}.startup | head -1`
        CMD=`grep "ip addr" as${ASN}${i}.startup | wc -l`
        if [ $CMD -ge 1 ] ; then
                IP=`grep "ip addr" as${ASN}${i}.startup | head -1 | cut -d " " -f 4 | cut -d "/" -f 1`
        else
                IP=`grep "ifconfig" as${ASN}${i}.startup | head -1 | cut -d " " -f 3 | cut -d "/" -f 1`
		PENALTY=$(( $PENALTY + 1 ))
        fi
        echo -e " $INT\t$IP"
        echo "$INT $IP" > $i
        echo "$i $INT $IP" >> CONF_IP
        if [ "$INT" != "eth0" ] ; then
                echo "ERROR: $i interface is not eth0"
                echo "ERROR: $i interface is not eth0" >> $LOG
                exit 1
        fi
done

# check IP addresses are from your assigned IP address block
SERVER=(s1 s2 s3)
for i in ${SERVER[@]}
do
        #echo $i 
        IF=`grep eth0 $i | cut -d " " -f 1`
        FIRST=`grep eth0 $i | cut -d " " -f 2 | cut -d "." -f 1`
        SECOND=`grep eth0 $i | cut -d " " -f 2 | cut -d "." -f 2`
        #echo $IF $FIRST $SECOND
        if [ $FIRST -ne 1 ] && [ $SECOND -ne $ASN ] ; then
                echo "ERROR: $i ${IF} has wrong address: ${FIRST}.${SECOND}.x.x"
                echo "ERROR: $i ${IF} has wrong address: ${FIRST}.${SECOND}.x.x" >> $LOG
		IPPENALTY=$(( $IPPENALTY + 1 ))
                #exit 1
        fi
done
echo "1 servers" >> CONF_IP_POINTS

# check clients are running DHCP client service
CLIENT=(c1 c2)
for i in ${CLIENT[@]}
do
        echo $i >> $LOG
        if [ -f "${i}" ] ; then
                rm $i
        fi
        echo "# as${ASN}${i}"
        sed -i '/^#/d' as${ASN}${i}.startup
        sed -i '/^$/d' as${ASN}${i}.startup
        CTR=`cat as${ASN}${i}.startup | wc -l`
        DHCLIENT=`grep dhclient as${ASN}${i}.startup | wc -l`
        RELAY=`grep dhcp-relay as${ASN}${i}.startup | wc -l`

        if [ $DHCLIENT -eq 1 ]; then
            if [ $CTR -eq 1 ]; then
        	CMD=`grep dhclient as${ASN}${i}.startup | tr -d '\r' | cut -d " " -f 1 | rev | cut -d "/" -f 1| rev`
		INT=`grep dhclient as${ASN}${i}.startup | tr -d '\r' | cut -d " " -f 2`
                OK=1
                echo -e " $INT\t$CMD"
                echo "$INT $CMD $OK" > $i
                echo "$i $INT $CMD" >> CONF_IP
	    else
		echo "ERROR: $i startup script should have only the dhclient command "
		echo "ERROR: $i startup script should have only the dhclient command " >> $LOG
		DHCPPENALTY=$(( $DHCPPENALTY + 1 ))
	    fi
	    # Overwrite startup config
	    echo "/sbin/dhclient eth0" > as${ASN}${i}.startup
	else
	    # If dhclient is not used, assume it runs dhcrelay
            if [ $RELAY -eq 1 ]; then
                if [ $CTR -gt 1 ]; then
			INT=`grep -o '[^ ]*eth[^ ]*' as${ASN}${i}.startup | head -1`
                        CMD=`grep "ip addr" as${ASN}${i}.startup | wc -l`
			if [ $CMD -ge 1 ] ; then
                                IP=`grep "ip addr" as${ASN}${i}.startup | head -1 | cut -d " " -f 4 | cut -d "/" -f 1`
                        else
                                IP=`grep "ifconfig" as${ASN}${i}.startup | head -1 | cut -d " " -f 3 | cut -d "/" -f 1`
				PENALTY=$(( $PENALTY + 1 ))
                        fi
                        if [ "$INT" == "eth0" ] ; then
                                if [ "$IP" != "" ] ; then
                                        OK=1
                                        echo -e " $INT\t$IP"
                                        echo "$INT $IP $OK" > $i
                                        echo "$i $INT $IP RELAY" >> CONF_IP
                                else
                                        echo "ERROR: $i must have an IP address to run as a DHCP relay"
                                        echo "ERROR: $i must have an IP address to run as a DHCP relay" > $i
                                        exit 1
                                fi
			else
                                echo "ERROR: $i must use eth0"
                                echo "ERROR: $i must use eth0" >> $LOG
                                exit 1
                        fi


	        else
			echo "ERROR: $i must have an IP address when use as a DHCP relay"
			echo "ERROR: $i must have an IP address when use as a DHCP relay" >> $LOG
		fi
	    else
		echo "ERROR: $i startup script should have only the dhclient command "
		echo "ERROR: $i startup script should have only the dhclient command " >> $LOG
		DHCPPENALTY=$(( $DHCPPENALTY + 1 ))
	        # Overwrite startup config
	        echo "/sbin/dhclient eth0" > as${ASN}${i}.startup
	    fi
	fi
done
echo "1 clients" >> CONF_IP_POINTS
###### END: GET DEVICE INTERFACE IP ADDRESS

###### BEGIN: CHECK INTERNET SERVICES
echo "### CHECK Internet services"
if [ -f "CONF_SERVICES" ] ; then
        rm CONF_SERVICES
fi

echo "named" >> $LOG
grep named as${ASN}s*startup > TMP
sed -i '/^#/d' TMP
SERV=`cat TMP | wc -l`
SERVS1=`grep named as${ASN}s1.startup | wc -l`
if [ $SERV -eq 1 ] && [ $SERVS1 -eq 1 ] ; then
        DNS=`sed "s/as${ASN}//" TMP | cut -d "." -f1`
        echo -e " dns\t$DNS"
        echo "dns $DNS 1" >> CONF_SERVICES
	# Overwrite named startup config on s1
	IP=`grep -e "ip addr" -e "ifconfig" as${ASN}s1.startup`
	ROUTE=`grep -e "route add" -e "ifconfig" as${ASN}s1.startup`
	echo $IP > as${ASN}s1.startup
	echo $ROUTE >> as${ASN}s1.startup
	echo "systemctl start named" >> as${ASN}s1.startup
else
	OTHERS=`grep named as${ASN}s*startup | cut -d ":" -f 1 | grep -e "s2" -e "s3" | wc -l`
	if [ $OTHERS -ge 1 ]; then
        	echo "ERROR: you should run named on only s1"
        	echo "ERROR: you should run named on only s1" >> $LOG
        	echo "dns $DNS 0" >> CONF_SERVICES
        	exit 1
	else
		# Overwrite named startup config on s1
		IP=`grep -e "ip addr" -e "ifconfig" as${ASN}s1.startup`
		ROUTE=`grep -e "route add" -e "ifconfig" as${ASN}s1.startup`
		echo $IP > as${ASN}s1.startup
		echo $ROUTE >> as${ASN}s1.startup
		echo "systemctl start named" >> as${ASN}s1.startup
		DNSPENALTY=$(( $DNSPENALTY + 1 ))
	fi
fi

echo "apache2" >> $LOG
grep apache2 as${ASN}s*startup > TMP
sed -i '/^#/d' TMP
SERV=`cat TMP | wc -l`
if [ $SERV -eq 1 ] ; then
        WWW=`sed "s/as${ASN}//" TMP | cut -d "." -f1`
        if [ "$WWW" != "$DNS" ] ; then
                echo -e " www\t$WWW"
                echo "www $WWW 1" >> CONF_SERVICES
		# Overwrite startup config
		SERV=`grep apache2 as${ASN}s*startup | cut -d ":" -f 1`
		IP=`grep -e "ip addr" -e "ifconfig" ${SERV}`
		ROUTE=`grep -e "route add" -e "ifconfig" ${SERV}`
		echo $IP > ${SERV}
		echo $ROUTE >> ${SERV}
		echo "systemctl start apache2" >> ${SERV}
        else
                echo "ERROR: dns and web services cannot be on the same server"
                echo "ERROR: dns and web services cannot be on the same server" >> $LOG
                echo "www $WWW 0" >> CONF_SERVICES
                exit 1
        fi
elif [ $SERV -gt 1 ] ; then
        echo "ERROR: you should run apache2 on only one server"
        echo "ERROR: you should run apache2 on only one server" >> $LOG
        echo "www $WWW 0" >> CONF_SERVICES
        exit 1
else
	grep apachectl as${ASN}s*startup > TMP
	sed -i '/^#/d' TMP
	SERV=`cat TMP | wc -l`
	if [ $SERV -ge 1 ] ; then
		WWWPENALTY=$(( $WWWPENALTY + 1 ))
	fi
        WWW=`sed "s/as${ASN}//" TMP | cut -d "." -f1`
        if [ "$WWW" != "$DNS" ] ; then
                echo -e " www\t$WWW"
                echo "www $WWW 1" >> CONF_SERVICES
		# Overwrite startup config
		SERV=`grep apachectl as${ASN}s*startup | cut -d ":" -f 1`
		IP=`grep -e "ip addr" -e "ifconfig" ${SERV}`
		ROUTE=`grep -e "route add" -e "ifconfig" ${SERV}`
		echo $IP > ${SERV}
		echo $ROUTE >> ${SERV}
		echo "systemctl start apache2" >> ${SERV}
        else
                echo "ERROR: dns and web services cannot be on the same server"
                echo "ERROR: dns and web services cannot be on the same server" >> $LOG
                echo "www $WWW 0" >> CONF_SERVICES
                exit 1
        fi
fi

echo "isc-dhcp-server" >> $LOG
grep dhcp-server as${ASN}s*startup > TMP
sed -i '/^#/d' TMP
SERV=`cat TMP | wc -l`
if [ $SERV -eq 1 ] ; then
        DHCPD=`sed "s/as${ASN}//" TMP | cut -d "." -f1`
        if [ "$DHCPD" != "$DNS" ] ; then
                echo -e " dhcpd\t$DHCPD"
                echo "dhcpd $DHCPD 1" >> CONF_SERVICES
		# Overwrite startup config
		SERV=`grep dhcp-server as${ASN}s*startup | cut -d ":" -f 1`
		IP=`grep -e "ip addr" -e "ifconfig" ${SERV}`
		ROUTE=`grep -e "route add" -e "ifconfig" ${SERV}`
		echo $IP > ${SERV}
		echo $ROUTE >> ${SERV}
		echo "systemctl start isc-dhcp-server" >> ${SERV}
        else
                echo "ERROR: dns and web services cannot be on the same server"
                echo "ERROR: dns and web services cannot be on the same server" >> $LOG
                echo "dhcpd $DHCPD 0" >> CONF_SERVICES
                exit 1
        fi
elif [ $SERV -gt 1 ] ; then
        echo "ERROR: you should run isc-dhcp-server on only one server"
        echo "ERROR: you should run isc-dhcp-server on only one server" >> $LOG
        echo "dhcpd $DHCPD 0" >> CONF_SERVICES
        exit 1
else
        echo "ERROR: you should run isc-dhcp-server on at least one server"
        echo "ERROR: you should run isc-dhcp-server on at least one server" >> $LOG
        echo "dhcpd $DHCPD 0" >> CONF_SERVICES
        exit 1
fi

echo "isc-dhcp-relay" >> $LOG
grep dhcp-relay as${ASN}*startup > TMP
sed -i '/^#/d' TMP
SERV=`cat TMP | wc -l`
if [ $SERV -eq 1 ] ; then
        RELAY=`sed "s/as${ASN}//" TMP | cut -d "." -f1`
        if [ "$RELAY" == "r4" ] || [ "$RELAY" == "c1" ] || [ "$RELAY" == "c2" ] ; then
                echo -e " relay\t$RELAY"
                echo "relay $RELAY 1" >> CONF_SERVICES
        else
                echo "ERROR: DHCP relay must be on the client network"
                echo "ERROR: DHCP relay must be on the client network" >> $LOG
                echo "relay $RELAY 0" >> CONF_SERVICES
                exit 1
        fi
elif [ $SERV -gt 1 ] ; then
        echo "ERROR: you should run isc-dhcp-relay on only one device"
        echo "ERROR: you should run isc-dhcp-relay on only one device" >> $LOG
        echo "relay $RELAY 0" >> CONF_SERVICES
        #exit 1
else 
        echo "ERROR: you must run isc-dhcp-relay on at least one device"
        echo "ERROR: you must run isc-dhcp-relay on at least one device" >> $LOG
        echo "relay $RELAY 0" >> CONF_SERVICES
	DHCPPENALTY=$(( $DHCPPENALTY + 1 ))
        #exit 1
fi
###### END: CHECK INTERNET CONF_SERVICES

###### BEGIN: CHECK NO BGP ON R3 and R4
echo "### CHECK eBGP peering configuration"
if [ -f "CONF_BGP" ] ; then
        rm CONF_BGP
fi

R1BGP=`grep "1.0.0.4 remote-as 1" as${ASN}r1/etc/frr/frr.conf | wc -l`
if [ $R1BGP -ne 1 ] ; then
	echo "ERROR: r1 must have eBGP peering with AS1"
	echo "ERROR: r1 must have eBGP peering with AS1" >> $LOG
	echo -e "r1 0" >> CONF_BGP
else 
	echo " r1 has an eBGP peering with AS1"
	echo -e "r1 1" >> CONF_BGP
fi
R2BGP=`grep "2.21.0.0 remote-as 21" as${ASN}r2/etc/frr/frr.conf | wc -l`
if [ $R2BGP -ne 1 ] ; then
	echo "ERROR: r2 must have eBGP peering with AS21"
	echo "ERROR: r2 must have eBGP peering with AS21" >> $LOG
	echo -e "r2 0" >> CONF_BGP
else 
	echo " r2 has an eBGP peering with AS21"
	echo -e "r2 1" >> CONF_BGP
fi
R3BGP=`ls as${ASN}r3/etc/frr | grep bgp | wc -l`
if [ $R3BGP -eq 1 ] ; then
	echo "ERROR: you cannot run BGP on r3"
	echo "ERROR: you cannot run BGP on r3" >> $LOG
	echo -e "r3 0" >> CONF_BGP
	rm as${ASN}r3/etc/frr/frr.conf
else 
	echo " r3 is a non-BGP router"
	echo -e "r3 1" >> CONF_BGP
fi
R3BGP=`grep "bgpd=yes" as${ASN}r3/etc/frr/daemons | wc -l`
if [ $R3BGP -eq 1 ] ; then
	sed -i "s/bgpd=yes/bgpd=no/" as${ASN}r3/etc/frr/daemons
	BGPPENALTY=$(( BGPPENALTY + 1 ))
fi
R4BGP=`ls as${ASN}r4/etc/frr | grep bgp | wc -l`
if [ $R4BGP -eq 1 ] ; then
	echo "ERROR: you cannot run BGP on r4"
	echo "ERROR: you cannot run BGP on r4" >> $LOG
	echo -e "r4 0" >> CONF_BGP
	rm as${ASN}r4/etc/frr/frr.conf
else 
	echo " r4 is a non-BGP router"
	echo -e "r4 1" >> CONF_BGP
fi
R4BGP=`grep "bgpd=yes" as${ASN}r4/etc/frr/daemons | wc -l`
if [ $R4BGP -eq 1 ] ; then
	sed -i "s/bgpd=yes/bgpd=no/" as${ASN}r4/etc/frr/daemons
	BGPPENALTY=$(( BGPPENALTY + 1 ))
fi
STATIC=`grep -h "ip route" as${ASN}r*/etc/frr/*conf | sed 's/^[ \t]*//' | sed '/conf:!/d' | wc -l`
if [ $STATIC -ge 1 ] ; then
	echo "ERROR: you should not use static route"
	STATICPENALTY=$(( STATICPENALTY + 1 ))
fi

###### END: CHECK NO BGP ON R3 and R4

###### check completed
#echo "##### check completed."
#echo "If you see an ERROR in the output, you need to troubleshoot and fix it"
#
#if [ $ERR -gt 0 ]; then
#  echo "##### RESULT: FAIL"
#else
#  echo "##### RESULT: OK"
#fi
#echo ""
#echo "IMPORTANT: This script only checks basic configurations and does not test your network."
#echo "It is your task to test and verify that everything works properly!"
#echo "The result above means:"
#echo -e "FAIL:\tyour submission definitely fails and won't be tested with our verfication tool!"
#echo -e "OK:\tyour submission will be tested with our verification tool"
##### go back to the current folder
echo $PENALTY > PENALTY
echo $IPPENALTY > IPPENALTY
echo $DNSPENALTY > PENALTY_DNS
echo $WWWPENALTY > PENALTY_WWW
echo $DHCPPENALTY > PENALTY_DHCP
echo $BGPPENALTY > PENALTY_BGP
echo $STATICPENALTY > PENALTY_STATIC
cd $CURRENT
#exit $ERR

  if [ $ERR -eq 0 ] ; then
          #echo "check config OK"
          echo "### OK: NO ERROR"
  else
          #echo "check config FAIL"
          echo "### FAIL: YOU NEED TO FIX THE ERROR!"
#          cat ${TEST_FOLDER}/$LOG >> $RESULTS
#          mv $RESULTS ${TEST_FOLDER}
          exit 1
  fi

if [ -d $TEST_FOLDER ] ; then
  rm -fR $TEST_FOLDER
fi

echo "##### END CHECKING CONFIGURATIONS"
echo ""
echo "NOTE: It is very important that the clients can get IP address via DHCP."
echo "Otherwise, the verification test cannot proceed and fail"
echo "Thus, you must ensure that they are properly working"
