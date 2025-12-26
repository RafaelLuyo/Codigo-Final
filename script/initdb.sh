#!/bin/bash

until mongosh --host localhost --eval "print('Esperando a que levante mongo..')" &> /dev/null; do
    sleep 3
done

mongoimport --host localhost --db database --collection usuarios --file /data/mongo.json --jsonArray

echo "Datos importados correctamente"