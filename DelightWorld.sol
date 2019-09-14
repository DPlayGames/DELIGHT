pragma solidity ^0.5.9;

import "./DelightSub.sol";
import "./Util/SafeMath.sol";

// 월드 관련 처리
contract DelightWorld is DelightSub {
	using SafeMath for uint;
	
	// Events
	// 이벤트
    event Build				(address indexed owner, uint buildingId, uint kind, uint col, uint row, uint bulidTime, uint wood, uint stone, uint iron, uint ducat);
    event UpgradeHQ			(address indexed owner, uint buildingId, uint level, uint col, uint row, uint wood, uint stone, uint iron, uint ducat);
    event DestroyBuilding	(address indexed owner, uint buildingId, uint kind, uint col, uint row);
    
    event CreateArmy		(address indexed owner, uint armyId, uint unitKind, uint unitCount, uint col, uint row, uint createTime, uint wood, uint stone, uint iron, uint ducat);
    event AddUnits			(address indexed owner, uint armyId, uint unitKind, uint unitCount, uint col, uint row, uint wood, uint stone, uint iron, uint ducat);
    
	// 지형의 범위
	uint constant internal COL_RANGE = 100;
	uint constant internal ROW_RANGE = 100;
	
	// 한 위치에 존재할 수 있는 최대 유닛 수
	uint constant internal MAX_POSITION_UNIT_COUNT = 50;
	
	Building[] internal buildings;
	Army[] internal armies;
	
	mapping(uint => mapping(uint => uint)) internal positionToBuildingId;
	mapping(uint => mapping(uint => uint[])) internal positionToArmyIds;
	
	mapping(address => uint[]) internal ownerToHQIds;
	
	// 올바른 범위인지 체크합니다.
	modifier checkRange(uint col, uint row) {
		require(col < COL_RANGE && row < ROW_RANGE);
		_;
	}
	
	constructor() DelightSub() public {
		
		// 0번지는 사용하지 않습니다.
		buildings.push(Building({
			kind : 99,
			level : 0,
			col : COL_RANGE,
			row : ROW_RANGE,
			owner : msg.sender,
			buildTime : now
		}));
		
		// 0번지는 사용하지 않습니다.
		armies.push(Army({
			unitKind : 99,
			unitCount : 0,
			knightItemId : 0,
			col : COL_RANGE,
			row : ROW_RANGE,
			owner : msg.sender,
			createTime : now
		}));
	}
	
	// 특정 위치에 존재하는 부대의 소유주를 가져옵니다.
	function getArmyOwnerByPosition(uint col, uint row) view internal returns (address) {
		
		uint[] memory armyIds = positionToArmyIds[col][row];
		
		for (uint i = 0; i < armyIds.length; i += 1) {
			
			address owner = armies[armyIds[i]].owner;
			if (owner != address(0x0)) {
				return owner;
			}
		}
		
		return address(0x0);
	}
	
	// 건물을 짓습니다.
	function build(address owner, uint kind, uint col, uint row) onlyDelight checkRange(col, row) external returns (uint) {
		
		// 필드에 건물이 존재하면 안됩니다.
		require(positionToBuildingId[col][row] == 0);
		
		// 필드에 적군이 존재하면 안됩니다.
		require(positionToArmyIds[col][row].length == 0 || getArmyOwnerByPosition(col, row) == owner);
		
		// 본부가 주변에 존재하는지 확인합니다.
		bool existsHQAround = false;
		for (uint i = 0; i < ownerToHQIds[owner].length; i += 1) {
			
			Building memory building = buildings[ownerToHQIds[owner][i]];
			uint hqCol = building.col;
			uint hqRow = building.row;
			
			if (
				(col < hqCol ? hqCol - col : col - hqCol) +
				(row < hqRow ? hqRow - row : row - hqRow) <= 5 + building.level.mul(2)
			) {
				existsHQAround = true;
				break;
			}
		}
		
		// 월드에 본부가 아예 없거나, 본부가 주변에 존재하는지 확인합니다.
		require(ownerToHQIds[owner].length == 0 || existsHQAround == true ||
		// 본부인 경우, 내 병사가 있는 위치에 지을 수 있습니다.
		(
			kind == BUILDING_HQ &&
			positionToArmyIds[col][row].length > 0 &&
			getArmyOwnerByPosition(col, row) == owner
		));
		
		// 만약 월드에 본부가 아예 없는 경우, 처음 짓는 곳 주변에 건물이 존재하면 안됩니다.
		if (ownerToHQIds[owner].length == 0) {
			for (uint i = (col <= 9 ? 0 : col - 9); i < (col >= 91 ? 100 : col + 9); i += 1) {
				for (uint j = (row <= 9 ? 0 : row - 9); j < (row >= 91 ? 100 : row + 9); j += 1) {
					require(positionToBuildingId[i][j] == 0);
				}
			}
		}
		
		Material memory material = buildingMaterials[kind];
		
		// 건물을 짓는데 필요한 자원이 충분한지 확인합니다.
		require(
			wood.balanceOf(owner) >= material.wood &&
			stone.balanceOf(owner) >= material.stone &&
			iron.balanceOf(owner) >= material.iron &&
			ducat.balanceOf(owner) >= material.ducat
		);
		
		uint bulidTime = now;
		
		uint buildingId = buildings.push(Building({
			kind : kind,
			level : 0,
			col : col,
			row : row,
			owner : owner,
			buildTime : now
		})).sub(1);
		
		positionToBuildingId[col][row] = buildingId;
		
		if (kind == BUILDING_HQ) {
			ownerToHQIds[owner].push(buildingId);
		}
		
		// 자원을 Delight로 이전합니다.
		wood.transferFrom(owner, delight, material.wood);
		stone.transferFrom(owner, delight, material.stone);
		iron.transferFrom(owner, delight, material.iron);
		ducat.transferFrom(owner, delight, material.ducat);
		
		// 기록을 저장합니다.
		delightHistory.recordBuild(owner, buildingId, kind, col, row, material.wood, material.stone, material.iron, material.ducat);
		
		// 이벤트 발생
		emit Build(owner, buildingId, kind, col, row, bulidTime, material.wood, material.stone, material.iron, material.ducat);
		
		return buildingId;
	}
	
	// 본부를 업그레이드합니다.
	function upgradeHQ(address owner, uint buildingId) external {
		
		Building storage building = buildings[buildingId];
		
		require(building.kind == BUILDING_HQ);
		
		Material memory material = hpUpgradeMaterials[building.level + 1];
		
		// 본부를 업그레이드하는데 필요한 자원이 충분한지 확인합니다.
		require(
			wood.balanceOf(owner) >= material.wood &&
			stone.balanceOf(owner) >= material.stone &&
			iron.balanceOf(owner) >= material.iron &&
			ducat.balanceOf(owner) >= material.ducat
		);
		
		// 최대 레벨은 2입니다. (0 ~ 2)
		require(building.level < 2);
		
		building.level += 1;
		
		// 자원을 Delight로 이전합니다.
		wood.transferFrom(owner, delight, material.wood);
		stone.transferFrom(owner, delight, material.stone);
		iron.transferFrom(owner, delight, material.iron);
		ducat.transferFrom(owner, delight, material.ducat);
		
		// 기록을 저장합니다.
		delightHistory.recordUpgradeHQ(owner, buildingId, building.level, building.col, building.row, material.wood, material.stone, material.iron, material.ducat);
		
		// 이벤트 발생
		emit UpgradeHQ(building.owner, buildingId, building.level, building.col, building.row, material.wood, material.stone, material.iron, material.ducat);
	}
	
	// 건물에서 부대를 생산합니다.
	function createArmy(address owner, uint buildingId, uint unitCount) external returns (uint) {
		
		// 건물 소유주만 부대 생산이 가능합니다.
		require(buildings[buildingId].owner == owner);
		
		// 건물이 위치한 곳의 총 유닛 숫자를 계산합니다.
		uint[] storage armyIds = positionToArmyIds[buildings[buildingId].col][buildings[buildingId].row];
		
		uint totalUnitCount = unitCount;
		for (uint i = 0; i < armyIds.length; i += 1) {
			totalUnitCount = totalUnitCount.add(armies[armyIds[i]].unitCount);
		}
		
		// 건물이 위치한 곳의 총 유닛 숫자가 최대 유닛 수를 넘기면 안됩니다.
		require(totalUnitCount <= MAX_POSITION_UNIT_COUNT);
		
		uint unitKind;
		
		// 본부의 경우 기사를 생산합니다.
		if (buildings[buildingId].kind == BUILDING_HQ) {
			
			// 이미 기사가 존재하는 곳이면, 취소합니다.
			if (armyIds.length == UNIT_KIND_COUNT && armyIds[UNIT_KNIGHT] != 0) {
				revert();
			} else {
				unitKind = UNIT_KNIGHT;
			}
		}
		
		// 훈련소의 경우 검병을 생산합니다.
		else if (buildings[buildingId].kind == BUILDING_TRAINING_CENTER) {
			unitKind = UNIT_SWORDSMAN;
		}
		
		// 사격소의 경우 궁수를 생산합니다.
		else if (buildings[buildingId].kind == BUILDING_TRAINING_CENTER) {
			unitKind = UNIT_ARCHER;
		}
		
		// 마굿간의 경우 기마병을 생산합니다.
		else if (buildings[buildingId].kind == BUILDING_STABLE) {
			unitKind = UNIT_CAVALY;
		}
		
		else {
			revert();
		}
		
		Material memory material = Material({
			wood : unitMaterials[unitKind].wood.mul(unitCount),
			stone : unitMaterials[unitKind].stone.mul(unitCount),
			iron : unitMaterials[unitKind].iron.mul(unitCount),
			ducat : unitMaterials[unitKind].ducat.mul(unitCount)
		});
		
		// 부대를 생성하는데 필요한 자원이 충분한지 확인합니다.
		require(
			wood.balanceOf(owner) >= material.wood &&
			stone.balanceOf(owner) >= material.stone &&
			iron.balanceOf(owner) >= material.iron &&
			ducat.balanceOf(owner) >= material.ducat
		);
		
		armyIds.length = UNIT_KIND_COUNT;
		
		// 기존에 부대가 존재하면 부대원의 숫자 증가
		if (armyIds[unitKind] != 0) {
			
			armies[armyIds[unitKind]].unitCount = armies[armyIds[unitKind]].unitCount.add(unitCount);
			
			// 기록을 저장합니다.
			delightHistory.recordAddUnits(owner, buildingId, buildings[buildingId].kind, buildings[buildingId].level, buildings[buildingId].col, buildings[buildingId].row, armyIds[unitKind], unitKind, unitCount, material.wood, material.stone, material.iron, material.ducat);
			
			// 이벤트 발생
			emit AddUnits(owner, armyIds[unitKind], unitKind, unitCount, buildings[buildingId].col, buildings[buildingId].row, material.wood, material.stone, material.iron, material.ducat);
		}
		
		// 새 부대 생성
		else {
			
			armyIds[unitKind] = armies.push(Army({
				unitKind : unitKind,
				unitCount : unitCount,
				knightItemId : 0,
				col : buildings[buildingId].col,
				row : buildings[buildingId].row,
				owner : owner,
				createTime : now
			})).sub(1);
			
			// 기록을 저장합니다.
			delightHistory.recordCreateArmy(owner, buildingId, buildings[buildingId].kind, buildings[buildingId].level, buildings[buildingId].col, buildings[buildingId].row, armyIds[unitKind], unitKind, unitCount, material.wood, material.stone, material.iron, material.ducat);
			
			// 이벤트 발생
			emit CreateArmy(owner, armyIds[unitKind], unitKind, unitCount, buildings[buildingId].col, buildings[buildingId].row, now, material.wood, material.stone, material.iron, material.ducat);
		}
		
		// 자원을 Delight로 이전합니다.
		wood.transferFrom(owner, delight, material.wood);
		stone.transferFrom(owner, delight, material.stone);
		iron.transferFrom(owner, delight, material.iron);
		ducat.transferFrom(owner, delight, material.ducat);
		
		return armyIds[unitKind];
	}
}