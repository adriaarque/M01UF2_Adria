#!/bin/bash

PORT=3333
CLIENT="localhost"
TIMEOUT=1

echo "Servidor de EFTP"

echo "(0) Listen"

DATA=`nc -l -p $PORT -w $TIMEOUT`

echo $DATA

echo "(3) Test & Send"

PREFIX=`echo $DATA | cut -d " " -f 1`
VERSION=`echo $DATA | cut -d " " -f 2`

if [ "$PREFIX $VERSION" != "EFTP 1.0" ]
then
	echo "ERROR 1: BAD HEADER"
	sleep 1
	#echo "KO_HEADER" | nc $CLIENT $PORT
	exit 1
fi

CLIENT=`echo $DATA | cut -d " " -f 3`

if [ "$CLIENT" == "" ]
then
	echo "ERROR: NO IP"
	exit 1
fi

echo "OK_HEADER"
sleep 1
echo "OK_HEADER" | nc $CLIENT $PORT #envío

echo "(4) Listen"

DATA=`nc -l -p $PORT -w $TIMEOUT` #paso 4 escuchar

echo $DATA

echo "(7) Test & Send" #paso 7

if [ "$DATA" != "BOOOM" ] #paso 7
then
	echo "ERROR 2: BAD HANDSHAKE"
	sleep 1
	echo "KO_HANDSHAKE" | nc $CLIENT $PORT
	exit 2
fi

echo "OK_HANDSHAKE"
sleep 1
echo "OK_HANDSHAKE" | nc $CLIENT $PORT



echo "(7a) Listen NUM_FILES"

DATA=`nc -l -p $PORT -w $TIMEOUT`

echo $DATA


echo "(7b) Send OK/KO_NUM_FILES"

PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "NUM_FILES" ]
then
	echo "ERROR 3a: WRONG NUM_FILES PREFIX"

	echo "KO_FILE_NUM" | nc $CLIENT $PORT

	exit 3
fi

echo "OK_FILE_NUM" | nc $CLIENT $PORT

FILE_NUM=`echo $DATA | cut -d " " -f 2`

for N in `seq $FILE_NUM`
do

echo "Archivo número $N"




echo "(8b) Listen"

DATA=`nc -l -p $PORT -w $TIMEOUT`

echo $DATA

echo "(12) Test&Store&Send"

PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "FILE_NAME" ]
then
	echo "ERROR 3: BAD FILE NAME PREFIX"
	sleep 1
	echo "KO_FILE_NAME" | nc $CLIENT $PORT
	exit 3
fi

FILE_NAME=`echo $DATA | cut -d " " -f 2`
FILE_MD5=`echo $DATA | cut -d " " -f 3`

FILE_MD5_LOCAL=`echo $FILE_NAME | md5sum | cut -d " " -f 1`

if [ "$FILE_MD5" != "$FILE_MD5_LOCAL" ]
then
	echo "ERROR 3: BAD FILE NAME MD5"
	sleep 1
	echo "KO_FILE_NAME" | nc $CLIENT $PORT
	exit 3
fi

echo "OK_FILE_NAME" | nc $CLIENT $PORT

#(arriba) cortamos con el delimitador que es el espacio y nos quedamos con la 2a columna que es el nombre

echo "(13) Listen"

nc -l -p $PORT -w $TIMEOUT > inbox/$FILE_NAME

DATA=`cat inbox/$FILE_NAME`

echo "(16) Store & Send"

if [ "DATA" == "" ]
then
	echo "ERROR 4: EMPTY DATA"
	sleep 1
	echo "KO_DATA" | nc $CLIENT $PORT
	exit 4
fi


sleep 1
echo "OK_DATA" | nc $CLIENT $PORT

echo "(17) Listen"

DATA=`nc -l -p $PORT -w $TIMEOUT`

echo "(20) Test&Send"

echo $DATA

PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "FILE_MD5" ]
then
	echo "ERROR 5: BAD FILE MD5 PREFIX"
	echo "KO_FILE_MD5" | nc $CLIENT $PORT
	exit 5
fi

FILE_MD5=`echo $DATA | cut -d " " -f 2`

FILE_MD5_LOCAL=`cat inbox/$FILE_NAME | md5sum | cut -d " " -f 1`

if [ "$FILE_MD5" != "$FILE_MD5_LOCAL" ]
then
	echo "ERROR 5: BAD FILE MD5"
	echo "KO_FILE_MD5" | nc $CLIENT $PORT
	exit 5
fi

echo "OK_FILE_MD5" | nc $CLIENT $PORT

done

echo "FIN"
exit 0
