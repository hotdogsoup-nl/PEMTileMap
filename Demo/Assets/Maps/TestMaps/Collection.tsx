<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.8" tiledversion="1.8.4" name="Collection" tilewidth="64" tileheight="64" tilecount="5" columns="0">
 <grid orientation="orthogonal" width="16" height="16"/>
 <tile id="10" type="its a type">
  <properties>
   <property name="eenprop" value="klopt"/>
  </properties>
  <image width="16" height="16" source="Tiles/disk_01.png"/>
 </tile>
 <tile id="11">
  <image width="16" height="16" source="Tiles/disk_02.png"/>
 </tile>
 <tile id="14" type="animation roo">
  <image width="16" height="24" source="animated1.png"/>
  <animation>
   <frame tileid="14" duration="250"/>
   <frame tileid="15" duration="250"/>
  </animation>
 </tile>
 <tile id="15" type="normal roo">
  <image width="16" height="24" source="animated2.png"/>
 </tile>
 <tile id="16">
  <image width="64" height="64" source="hotdogsoup-icon-full.png"/>
 </tile>
</tileset>
