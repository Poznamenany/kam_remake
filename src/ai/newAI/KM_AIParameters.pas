unit KM_AIParameters;
{$I KaM_Remake.inc}

interface
uses
  SysUtils;

// Global constants for AI
//const

  
// Global variables for AI
// They are stored in this file so Runner and Parallel runner can access it
var


{ KM_ArmyAttack }


{ KM_ArmyDefence }


{ KM_ArmyManagement }


{ KM_CityBuilder }
  GA_BUILDER_BuildHouse_FieldMaxWork                 : Single =  1;
  GA_BUILDER_BuildHouse_RTPMaxWork                   : Single =  5;
  GA_BUILDER_BuildHouse_RoadMaxWork                  : Single = 16;
  GA_BUILDER_CreateShortcuts_MaxWork                 : Single = 10;
  GA_BUILDER_ChHTB_FractionCoef                      : Single =  9.352;
  GA_BUILDER_ChHTB_TrunkFactor                       : Single = 16.045;
  GA_BUILDER_ChHTB_TrunkBalance                      : Single =  2.511;
  GA_BUILDER_ChHTB_AllWorkerCoef                     : Single =  7.154;
  GA_BUILDER_ChHTB_FreeWorkerCoef                    : Single =  4.251;
  GA_BUILDER_Shortage_Stone                          : Single = 13.772;
  GA_BUILDER_Shortage_StoneNoQuarry                  : Single = 30.000;
  GA_BUILDER_Shortage_Gold                           : Single = 27.638;
  GA_BUILDER_Shortage_Trunk                          : Single =  3.360;
  GA_BUILDER_Shortage_Wood                           : Single = 12.890;


{ KM_CityManagement }
//{
  GA_MANAGEMENT_CheckUnitCount_SerfCoef              : Single = 0.300717055797576;
  GA_MANAGEMENT_CheckUnitCount_SerfLimit             : Single = 0.709280669689178;
//}
{
  GA_MANAGEMENT_CheckUnitCount_SerfCoef              : Single = 0.393;
  GA_MANAGEMENT_CheckUnitCount_SerfLimit             : Single = 0.825;
//}
{
  GA_MANAGEMENT_CheckUnitCount_SerfCoef              : Single = 0.193;
  GA_MANAGEMENT_CheckUnitCount_SerfLimit             : Single = 2.179;
//}


{ KM_CityPlanner }
  GA_PLANNER_FindPlaceForHouse_AllyInfluence         : Single =  1; // 0..255
  GA_PLANNER_FindPlaceForHouse_EnemyInfluence        : Single = 10; // 0..255
  GA_PLANNER_FindForestAndWoodcutter_AllyInfluence   : Single =  3; // 0..255
  GA_PLANNER_FindForestAndWoodcutter_EnemyInfluence  : Single = 10; // 0..255

  GA_PLANNER_ObstaclesInHousePlan_Tree               : Single = 788.3220911;
  GA_PLANNER_ObstaclesInHousePlan_Road               : Single = 219.6835876;
  GA_PLANNER_FieldCrit_PolyRoute                     : Single =   2.883937657;
  GA_PLANNER_FieldCrit_FlatArea                      : Single =   1.613979578;
  GA_PLANNER_FieldCrit_Soil                          : Single =   2.607529342;
  GA_PLANNER_SnapCrit_SnapToHouse                    : Single =   0;
  GA_PLANNER_SnapCrit_SnapToFields                   : Single =   0.288372883;
  GA_PLANNER_SnapCrit_SnapToRoads                    : Single =   7.870791852;
  GA_PLANNER_SnapCrit_ClearEntrance                  : Single =  19.17334318;
  GA_PLANNER_FindPlaceForHouse_SnapCrit              : Single =   1.07497108;
  GA_PLANNER_FindPlaceForHouse_HouseDist             : Single =  18.67234826;
  GA_PLANNER_FindPlaceForHouse_SeedDist              : Single =  42.05959439;
  GA_PLANNER_FindPlaceForHouse_CityCenter            : Single =  43.24023426;
  GA_PLANNER_FindPlaceForHouse_Route                 : Single =   3.326784611;
  GA_PLANNER_FindPlaceForHouse_FlatArea              : Single =   1.945348799;
  GA_PLANNER_FindPlaceForHouse_RouteFarm             : Single =  -1.3515504;
  GA_PLANNER_FindPlaceForHouse_FlatAreaFarm          : Single =  -5;
  GA_PLANNER_FindPlaceForHouse_HouseDistFarm         : Single =   4.647785425;
  GA_PLANNER_FindPlaceForHouse_CityCenterFarm        : Single =  23.23892713;
  GA_PLANNER_PlaceWoodcutter_DistFromForest	         : Single =   0.899758935;

  GA_PLANNER_PlanFields_CanBuild                     : Word = 20;
  GA_PLANNER_PlanFields_Dist                         : Word =  6;
  GA_PLANNER_PlanFields_ExistField                   : Word = 51;
  GA_PLANNER_PlanFields_MaxFields                    : Word = 17;
  GA_PLANNER_PlanFields_MaxWine                      : Word = 10;

  GA_PLANNER_FindPlaceForQuary_Obstacle	             : Single =    48.6263424158097;
  GA_PLANNER_FindPlaceForQuary_DistCity	             : Single =     0;
  GA_PLANNER_FindPlaceForQuary_DistTimer             : Single = 12444.1891908646;
  GA_PLANNER_FindPlaceForQuary_DistStone             : Single =    34.244304895401;
  GA_PLANNER_FindPlaceForQuary_SnapCrit	             : Single =    36.5372747182846;

  GA_PLANNER_FindPlaceForWoodcutter_TreeCnt          : Single =    32.1456005573273;
  GA_PLANNER_FindPlaceForWoodcutter_TreeCntTimer     : Single = 13805.7332038879;
  GA_PLANNER_FindPlaceForWoodcutter_ExistForest      : Single =   406.349253058433;
  GA_PLANNER_FindPlaceForWoodcutter_Routes           : Single =     0.816604614257812;
  GA_PLANNER_FindPlaceForWoodcutter_FlatArea         : Single =     3.37718081474304;
  GA_PLANNER_FindPlaceForWoodcutter_Soil             : Single =     2.91867184638977;
  GA_PLANNER_FindPlaceForWoodcutter_DistCrit         : Single =     0.94243973493576;
  GA_PLANNER_FindPlaceForWoodcutter_DistTimer        : Single = 11655.6522846222;
  GA_PLANNER_FindPlaceForWoodcutter_FreeTiles        : Single =     3.34831988811493; // c
  GA_PLANNER_FindPlaceForWoodcutter_ABRange          : Single =   138.00858259201; // c
  GA_PLANNER_FindPlaceForWoodcutter_Radius           : Single =     4.72347187995911;
  GA_PLANNER_FindForestAround_MaxDist                : Single =     7.36316233873368; // c

// Note: it is interesting to see different GA strategy for pathfinding
// of first road to new house and pathfinding of shortcuts
//{
  GA_PATHFINDING_BasePrice                           : Word = 68;
  GA_PATHFINDING_Road                                : Word = 29;
  GA_PATHFINDING_noBuildArea                         : Word = 58;
  GA_PATHFINDING_Field                               : Word = 48;
  GA_PATHFINDING_Coal                                : Word =  0;
  GA_PATHFINDING_Forest                              : Word = 65;
  GA_PATHFINDING_OtherCase                           : Word = 29;
  GA_SHORTCUTS_BasePrice                             : Word = 75;
  GA_SHORTCUTS_Road                                  : Word = 45;
  GA_SHORTCUTS_noBuildArea                           : Word = 17;
  GA_SHORTCUTS_Field                                 : Word = 32;
  GA_SHORTCUTS_Coal                                  : Word = 13;
  GA_SHORTCUTS_Forest                                : Word = 13;
  GA_SHORTCUTS_OtherCase                             : Word = 26;
//}
{
  GA_PATHFINDING_BasePrice                           : Word = 34;
  GA_PATHFINDING_Road                                : Word = 34;
  GA_PATHFINDING_noBuildArea                         : Word = 14;
  GA_PATHFINDING_Field                               : Word = 41;
  GA_PATHFINDING_Coal                                : Word = 35;
  GA_PATHFINDING_Forest                              : Word = 50;
  GA_PATHFINDING_OtherCase                           : Word = 43;
  GA_SHORTCUTS_BasePrice                             : Word = 65;
  GA_SHORTCUTS_Road                                  : Word = 27;
  GA_SHORTCUTS_noBuildArea                           : Word = 27;
  GA_SHORTCUTS_Field                                 : Word = 47;
  GA_SHORTCUTS_Coal                                  : Word = 26;
  GA_SHORTCUTS_Forest                                : Word = 27;
  GA_SHORTCUTS_OtherCase                             : Word = 22;
//}


{ KM_CityPredictor }
//{ 2019_11_20
  GA_PREDICTOR_WareNeedPerAWorker_Stone              : Single = 0.65;
  GA_PREDICTOR_WareNeedPerAWorker_Wood               : Single = 0.28;
//}


{ KM_Eye }
//{
  GA_EYE_GetForests_MaxAB          : Single = 155.750323295593; // <0.201> Ignore trees in existing forest <0.255-AVOID_BUILDING_FOREST_MINIMUM)
  GA_EYE_GetForests_Radius         : Single =   8.670244455338; // Forest radius
  GA_EYE_GetForests_MinTrees       : Single =   3.150522664189; // Min trees in forest
  GA_EYE_GetForests_SPRndOwnLimMin : Single =  99.770336151123; // Minimum influence of potential forest
  GA_EYE_GetForests_SPRndOwnLimMax : Single = 201.641844511032; // Maximum influence of potential forest
  GA_EYE_GetForests_MinRndSoil     : Single =  81.396015167236; // 0-82
//}


{ KM_Supervisor }


implementation

end.
