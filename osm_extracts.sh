#!/bin/bash

# tool paths
osmium="$(pwd)/tools/osmium-tool/build/osmium"
splitter="$(pwd)/tools/splitter/splitter.jar"
mkgmap="$(pwd)/tools/mkgmap/mkgmap.jar"
osmosis="$(pwd)/tools/osmosis/bin/osmosis"
mapsforge="$(pwd)/tools/mapsforge/gradlew"
POIs_config="poi-mapping.xml"
PARENT_DIR=$(pwd)


#data inputs
osm_input="$PARENT_DIR/finland-latest.osm.pbf"
osm_output=output.osm.pbf
osm_output1=output1.osm.pbf
osm_output2=output2.osm.pbf
poi_file=$PARENT_DIR/POIs.poi
unpaved_typ="/mnt/g/garmin/typ files/unpaved2.typ"
paved_typ="/mnt/g/garmin/typ files/paved.typ"

clear

# Luodaan työhakemisto
if [ ! -d "data" ]; then
  mkdir -p "data"
fi
cd data
rm *.*

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
echo "4. lataa uusin osm suomi aineisto (.IMG)"
echo "0. Exit"
read choice

  case $choice in
    [1] )
      echo "processing"
      $osmium tags-filter "$osm_input" w/surface=unpaved,gravel,dirt,earth,fine_gravel,compacted,woodchips w/highway=track,unclassified w/piste:type -o $osm_output1
      $osmium tags-filter "$osm_output1" -i w/surface=asphalt,paved,concrete -o $osm_output
      java -Xmx6000M -jar "$splitter" $osm_output
      java -Xmx6000M -jar "$mkgmap" --family-id=7777 --family-name=Gravel_finland --mapname=88888888 --overview-mapname=Gravel_finland --area-name=gravel --country-name=FINLAND --country-abbr=FI --code-page=1252 --improve-overview --gmapsupp 6324*.osm.pbf  "$unpaved_typ"
      echo "renamed img to gravel"
      mv gmapsupp.img ../gravel.img
      cd ..
      rm -r data/
      exit 0
      ;;
    [2] )
      echo "processing"
      $osmium tags-filter "$osm_input" w/surface=asphalt,paved w/highway=secondary,tertiary -o $osm_output1
      $osmium tags-filter "$osm_output1" w/highway!=motorway,motorway_link,trunk -o $osm_output
      java -Xmx6000M -jar "$splitter" --mapid=63260002 $osm_output
      java -Xmx6000M -jar "$mkgmap" --family-id=7778 --family-name=Paved_finland --mapname=88888889 --series-name=Gravel --overview-mapname=paved_finland --improve-overview --country-name=FINLAND --country-abbr=FI --code-page=1252 --gmapsupp --gmapsupp 6326*.osm.pbf "$paved_typ"
      echo "renamed img to paved"
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
      echo $POIs_config
      $osmosis --rbf workers=5 file=$osm_input --poi-writer file=$poi_file
      exit 0
      ;;
    [4] )
      echo "processing"
      java -Xmx6000M -jar "$splitter" --mapid=63270003 $osm_input
      java -Xmx6000M -jar "$mkgmap" --family-id=7779 --family-name=Finland --mapname=88888890 --overview-mapname=Finland --country-name=FINLAND --country-abbr=FI --code-page=1252 --improve-overview --gmapsupp 6327*.osm.pbf
      echo "renamed img to finland"
      mv gmapsupp.img ../finland.img
      cd ..
      rm -r data/
      exit 0
      ;;
    [0] )
      echo "Exiting..."
      exit 0
      ;;
    * )
      clear
      ;;
  esac
done

exit 0