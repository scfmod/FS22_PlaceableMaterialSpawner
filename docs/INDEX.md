# Documentation

# Table of Contents

- [Add specialization to placeable type](#add-specialization-to-placeable-type)
- [Placeable XML](#placeable-xml)
- [Activation trigger](#activation-trigger)
- [SpawnArea](#spawnarea)
  - [Area](#area)
  - [Sounds](#sounds)
  - [Effect nodes](#effect-nodes)
  - [Animation nodes](#animation-nodes)

Documentation files:
- 🗎 [XSD validation schema](./schema/placeable_materialSpawner.xsd)
- 🗎 [HTML schema](./schema/placeable_materialSpawner.html)

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
                <!-- Supports using l10n texts from your mod -->
                <name>$l10n_conveyor</name>
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

## Activation trigger

```
placeable.materialSpawner.activationTrigger
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| node | node | No | | |

Player activation trigger for openening the control panel GUI. This allows you to change materials if applicable and disable/enable each spawn area. The collisionMask of node must have bit ```20``` (TRIGGER_PLAYER) set in order for it to function.

```xml
<placeable>
    ...
    <materialSpawner>
        <activationTrigger node="playerControlPanelTriggerNode" />
        ...
    </materialSpawner>
    ...
</placeable>
```

## SpawnArea

```
placeable.materialSpawner.spawnAreas.spawnArea(%)
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| name | string | No | | Name to show in control panel GUI |
| fillTypes | string | Yes | | Name of fillType(s) separated by whitespace |
| litersPerHour | int | No | ```100``` | Liters per hour to spawn |
| defaultEnabled | boolean | No | ```true``` | Set default enabled for spawn area |
| useProductionStorage | boolean | No | ```false``` | If placeable has ProductionPoint specialization, draw material out from the storage |

### Area

```
placeable.materialSpawner.spawnAreas.spawnArea(%).area
```

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| startNode | node | Yes | | |
| widthNode | node | Yes | | |
| heightNode | node | Yes | | |

### Sounds

```
placeable.materialSpawner.spawnAreas.spawnArea(%).sounds.work
placeable.materialSpawner.spawnAreas.spawnArea(%).sounds.work2
placeable.materialSpawner.spawnAreas.spawnArea(%).sounds.dropping
```


Uses the standard sample setup.

### Effect nodes

```
placeable.materialSpawner.spawnAreas.spawnArea(%).effectNodes(%)
```

Uses the standard effect nodes setup.

### Animation nodes

```
placeable.materialSpawner.spawnAreas.spawnArea(%).animationNodes(%)
```

Uses the standard animation nodes setup.