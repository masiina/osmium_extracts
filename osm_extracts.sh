#!/bin/bash

# tool paths
osmium="/home/masiina/tools/osmium-tool/build/osmium"
splitter="/home/masiina/tools/splitter/splitter.jar"
mkgmap="/home/masiina/tools/mkgmap/mkgmap.jar"
PARENT_DIR=$(pwd)

#data inputs
osm_input="$PARENT_DIR/finland-latest.osm.pbf"
osm_output=output.osm.pbf
osm_output1=output1.osm.pbf
osm_output2=output2.osm.pbf
unpaved_typ="/mnt/g/garmin/typ files/test.typ"
paved_typ="/mnt/g/garmin/typ files/paved.typ"
option=

clear


# Luodaan työhakemistot
if [ ! -d "data" ]; then
  mkdir -p "data"
fi
cd data

# tarkista että löytyykö osm data scriptin hakemistosta
if [ ! -f "$osm_input" ]; then
    echo -e "OSM tiedostoa $osm_input Ei löydyt, ladataan se\n"
    wget -P $PARENT_DIR https://download.geofabrik.de/europe/finland-latest.osm.pbf
    # Execute your command here
else
    echo -e "$osm_input löytyy, jatketaan\n"
fi


# Valikko
while true; do
echo "1. gravel reitit"
echo "2. pinnoitetut reitit"
echo "2. Exit"
read choice

  case $choice in
    [1] )
      echo "processing"
       $osmium tags-filter "$osm_input" w/surface=unpaved,gravel,dirt,earth,fine_gravel w/highway=track w/piste:type -o $osm_output
       option=$choice
      break
      ;;
    [2] )
      echo "processing"
       $osmium tags-filter "$osm_input" w/surface=asphalt,paved w/highway=secondary,tertiary -o $osm_output1
       $osmium tags-filter "$osm_output1" w/highway!=motorway,motorway_link,trunk -o $osm_output
       option=$choice
      break
      ;;
    [3] )
      echo "Exiting..."
      exit 0
      ;;
    * )
      clear
      ;;
  esac
done

# buildaus komennot jolla rakennetaan .img tiedosto
java -Xmx6000M -jar "$splitter" $osm_output

# nimeä tiedosto valinnan mukaan
case $option in
  [1] )
    java -Xmx6000M -jar "$mkgmap" --gmapsupp 6324*.osm.pbf "$unpaved_typ"
    echo "rename img to gravel"
    mv gmapsupp.img ../gravel.img
    ;;
  [2] )
    java -Xmx6000M -jar "$mkgmap" --gmapsupp 6324*.osm.pbf "$paved_typ"
    echo "rename img to gravel"
    mv gmapsupp.img ../paved.img
    ;;
  * )
    echo "Nothing to do, done"
    ;;
esac

# työtiedostojen poisto
cd ..
rm -r data/

echo "work done"
exit 0