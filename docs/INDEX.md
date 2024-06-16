# Documentation

# Table of Contents

- [Add specialization to placeable type](#add-specialization-to-placeable-type)
- [Placeable XML](#placeable-xml)
- [Activation trigger](#activation-trigger)


## Add specialization to placeable type

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc version="...">
    ...
    <placeableTypes>
        <!-- Extend parent type, can be anything -->
        <type name="mineShaft" parent="simplePlaceable" filename="$dataS/scripts/placeables/Placeable.lua">
            <specialization name="FS22_1_PlaceableMaterialSpawner.materialSpawner" />
        </type>
    </placeableTypes>
    ...
</modDesc>
```

## Placeable XML

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<placeable ...>
    ...
    <materialSpawner>
        <!-- Optional for enabling access to control panel GUI -->
        <activationTrigger node="..." />

        <spawnAreas>
            <!-- Define 1 or more spawn areas -->
            <spawnArea>
                <!-- Supports using l10n texts from mod -->
                <name>Conveyor</name>
                <litersPerHour>4000</litersPerHour>
                
                <!-- By choice you can define multiple filltypes. -->
                <!-- In order to enable GUI to change output, activationTrigger needs to be added -->
                <fillTypes>STONE</fillTypes>
                <!--
                <fillTypes>STONE IRONORE</fillTypes>
                -->

                <area startNode=".." widthNode=".." heightNode=".." />

                <!-- Optional -->
                <effectNodes>
                    ...
                </effectNodes>

                <!-- Optional -->
                <animationNodes>
                    ...
                </animationNodes>

                <!-- Optional -->
                <sounds>
                    <work .. />
                    <work2 .. />
                    <dropping .. />
                </sounds>
            </spawnArea>

            ...
        </spawnAreas>
    </materialSpawner>
</placeable>
```
