#!/bin/bash

CLIENT="localhost"
TIMEOUT=1

echo "Servidor de EFTP"

echo "(0) Listen"

DATA=`nc -l -p 3333 -w $TIMEOUT`

echo $DATA

echo "(3) Test & Send" #comprobar si lo que ha llegado es igual a la cabecera "EFTP 1.0"

if [ "$DATA" != "EFTP 1.0" ]
then
	echo "ERROR 1: BAD HEADER"
	sleep 1
	echo "KO_HEADER" | nc $CLIENT 3333
	exit 1
fi

echo "OK_HEADER"
sleep 1
echo "OK_HEADER" | nc $CLIENT 3333 #envío

echo "(4) Listen"

DATA=`nc -l -p 3333 -w $TIMEOUT` #paso 4 escuchar

echo $DATA

echo "(7) Test & Send" #paso 7

if [ "$DATA" != "BOOOM" ] #paso 7
then
	echo "ERROR 2: BAD HANDSHAKE"
	sleep 1
	echo "KO_HANDSHAKE" | nc $CLIENT 3333
	exit 2
fi

echo "OK_HANDSHAKE"
sleep 1
echo "OK_HANDSHAKE" | nc $CLIENT 3333

echo "(8) Listen"

DATA=`nc -l -p 3333 -w $TIMEOUT`

echo "(12) Test&Store&Send"

PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "FILE_NAME" ]
then
	echo "ERROR 3: BAD FILE NAME PREFIX"
	sleep 1
	echo "KO_FILE_NAME" | nc $CLIENT 3333
	exit 3
fi

FILE_NAME=`echo $DATA | cut -d " " -f 2` 

#(arriba) cortamos con el delimitador que es el espacio y nos quedamos con la 2a columna que es el nombre

echo "(13) Listen"

DATA=`nc -l -p 3333 -w $TIMEOUT`

echo "(16) Store & Send"

if [ "$DATA" == "" ]
then
	echo "ERROR 4: EMPTY DATA"
	sleep 1
	echo "KO_DATA" | nc $CLIENT 3333
	exit 4
fi

echo $DATA > inbox/$FILE_NAME

sleep 1
echo "OK_DATA" | nc $CLIENT 3333

exit 0
