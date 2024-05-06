#!/bin/bash

# tool paths
osmium="/home/masiina/tools/osmium-tool/build/osmium"
splitter="/home/masiina/tools/splitter/splitter.jar"
mkgmap="/home/masiina/tools/mkgmap/mkgmap.jar"
osmosis="/home/masiina/tools/osmosis/bin/osmosis"
mapsforge="/home/masiina/tools/mapsforge/gradlew"
PARENT_DIR=$(pwd)

#data inputs
osm_input="$PARENT_DIR/finland-latest.osm.pbf"
osm_output=output.osm.pbf
osm_output1=output1.osm.pbf
osm_output2=output2.osm.pbf
poi_file=$PARENT_DIR/POIs.poi
unpaved_typ="/mnt/g/garmin/typ files/test.typ"
paved_typ="/mnt/g/garmin/typ files/paved.typ"

clear

# Luodaan työhakemisto
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
echo "3. päivitä POIt"
echo "4. Exit"
read choice

  case $choice in
    [1] )
      echo "processing"
      $osmium tags-filter "$osm_input" w/surface=unpaved,gravel,dirt,earth,fine_gravel w/highway=track w/piste:type -o $osm_output
      java -Xmx6000M -jar "$splitter" $osm_output
      java -Xmx6000M -jar "$mkgmap" --gmapsupp 6324*.osm.pbf "$unpaved_typ"
      echo "rename img to gravel"
      mv gmapsupp.img ../gravel.img
      cd ..
      rm -r data/
      exit 0
      ;;
    [2] )
      echo "processing"
      $osmium tags-filter "$osm_input" w/surface=asphalt,paved w/highway=secondary,tertiary -o $osm_output1
      $osmium tags-filter "$osm_output1" w/highway!=motorway,motorway_link,trunk -o $osm_output
      java -Xmx6000M -jar "$splitter" $osm_output
      java -Xmx6000M -jar "$mkgmap" --gmapsupp 6324*.osm.pbf "$paved_typ"
      echo "rename img to gravel"
      mv gmapsupp.img ../paved.img
      cd ..
      rm -r data/
      exit 0
      ;;
    [3] )
      echo "processing"
      cd $(dirname $mapsforge)
      $mapsforge :mapsforge-poi-writer:fatjar
      mv mapsforge-poi-writer/build/libs/*.jar ../osmosis/bin/plugins/
      cd $(dirname $osmosis)
      $osmosis --rbf workers=5 file=$osm_input --poi-writer geo-tags=true ways=false file=$poi_file
      exit 0
      ;;
    [4] )
      echo "Exiting..."
      exit 0
      ;;
    * )
      clear
      ;;
  esac
done

exit 0