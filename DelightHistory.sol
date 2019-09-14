pragma solidity ^0.5.9;

import "./DelightHistoryInterface.sol";
import "./DelightBase.sol";
import "./Util/SafeMath.sol";

// 기록 관련 처리
contract DelightHistory is DelightHistoryInterface, DelightBase {
	using SafeMath for uint;
	
	// 기록의 종류
	uint constant internal RECORD_BUILD					= 0;
	uint constant internal RECORD_UPGRADE_HQ			= 1;
	uint constant internal RECORD_CREATE_ARMY			= 2;
	uint constant internal RECORD_ADD_UNITS				= 3;
	uint constant internal RECORD_MOVE_ARMY				= 4;
	uint constant internal RECORD_WIN					= 6;
	uint constant internal RECORD_LOSE					= 7;
	uint constant internal RECORD_RANGED_ATTACK			= 8;
	uint constant internal RECORD_CREATE_ITEM			= 9;
	uint constant internal RECORD_ATTACH_ITEM			= 10;
	uint constant internal RECORD_ATTACH_KNIGHT_ITEM	= 11;
	
	Record[] private history;
	mapping(uint => RecordDetail[]) private recordIdToDetails;
	
	// Delight World 주소
	address public delightWorld;
	
	// Delight Battle 주소
	address public delightBattle;
	
	function setDelightWorldOnce(address addr) external {
		
		// 비어있는 주소인 경우에만
		require(delightWorld == address(0));
		
		delightWorld = addr;
	}
	
	function setDelightBattleOnce(address addr) external {
		
		// 비어있는 주소인 경우에만
		require(delightBattle == address(0));
		
		delightBattle = addr;
	}
	
	// Sender가 Delight일때만 실행
	modifier onlyDelight() {
		require(
			msg.sender == delightWorld ||
			msg.sender == delightBattle
		);
		_;
	}
	
	constructor() DelightBase() public {
		
		// 0번지는 사용하지 않습니다.
		history.push(Record({
			kind : 99,
			
			owner : address(0x0),
			enemy : address(0x0),
			
			col : 0,
			row : 0,
			toCol : 0,
			toRow : 0,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0,
			
			time : now
		}));
	}
	
	// 건물 짓는 기록을 저장합니다.
	function recordBuild(
		
		address owner,
		
		// 건물 정보
		uint buildingId, uint buildingKind,
		uint col, uint row,
		
		// 재료
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_BUILD,
			
			owner : owner,
			enemy : address(0x0),
			
			col : col,
			row : row,
			toCol : 0,
			toRow : 0,
			
			buildingId : buildingId,
			buildingKind : buildingKind,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 본부를 업그레이드하는 기록을 저장합니다.
	function recordUpgradeHQ(
		
		address owner,
		
		// 건물 정보
		uint buildingId, uint buildingLevel,
		uint col, uint row,
		
		// 재료
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_UPGRADE_HQ,
			
			owner : owner,
			enemy : address(0x0),
			
			col : col,
			row : row,
			toCol : 0,
			toRow : 0,
			
			buildingId : buildingId,
			buildingKind : BUILDING_HQ,
			buildingLevel : buildingLevel,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 유닛을 추가하는 기록을 저장합니다.
	function recordAddUnits(
		
		address owner,
		
		// 건물 정보
		uint buildingId, uint buildingKind, uint buildingLevel,
		uint col, uint row,
		
		// 부대 정보
		uint armyId, uint unitKind, uint unitCount,
		
		// 재료
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_ADD_UNITS,
			
			owner : owner,
			enemy : address(0x0),
			
			col : col,
			row : row,
			toCol : 0,
			toRow : 0,
			
			buildingId : buildingId,
			buildingKind : buildingKind,
			buildingLevel : buildingLevel,
			
			armyId : armyId,
			unitKind : unitKind,
			unitCount : unitCount,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 부대를 생성하는 기록을 저장합니다.
	function recordCreateArmy(
		
		address owner,
		
		// 건물 정보
		uint buildingId, uint buildingKind, uint buildingLevel,
		uint col, uint row,
		
		// 부대 정보
		uint armyId, uint unitKind, uint unitCount,
		
		// 재료
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_CREATE_ARMY,
			
			owner : owner,
			enemy : address(0x0),
			
			col : col,
			row : row,
			toCol : 0,
			toRow : 0,
			
			buildingId : buildingId,
			buildingKind : buildingKind,
			buildingLevel : buildingLevel,
			
			armyId : armyId,
			unitKind : unitKind,
			unitCount : unitCount,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 아이템을 생성하는 기록을 저장합니다.
	function recordCreateItem(
		
		address owner,
		
		// 아이템 정보
		uint itemKind, uint itemCount,
		
		// 재료
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_CREATE_ITEM,
			
			owner : owner,
			enemy : address(0x0),
			
			col : 0,
			row : 0,
			toCol : 0,
			toRow : 0,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : itemKind,
			itemCount : itemCount,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 아이템을 장착하는 기록을 저장합니다.
	function recordAttachItem(
		
		address owner,
		
		// 아이템 정보
		uint itemKind, uint itemCount,
		
		// 부대 정보
		uint armyId, uint unitKind,
		uint col, uint row
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_ATTACH_ITEM,
			
			owner : owner,
			enemy : address(0x0),
			
			col : col,
			row : row,
			toCol : 0,
			toRow : 0,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : armyId,
			unitKind : unitKind,
			unitCount : itemCount,
			
			itemId : 0,
			itemKind : itemKind,
			itemCount : itemCount,
			
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0,
			
			time : now
		})).sub(1);
	}
	
	// 기사 아이템을 장착하는 기록을 저장합니다.
	function recordAttachKnightItem(
		
		address owner,
		
		// 아이템 정보
		uint itemId,
		
		// 부대 정보
		uint armyId,
		uint col, uint row
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_ATTACH_KNIGHT_ITEM,
			
			owner : owner,
			enemy : address(0x0),
			
			col : col,
			row : row,
			toCol : 0,
			toRow : 0,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : armyId,
			unitKind : UNIT_KNIGHT,
			unitCount : 1,
			
			itemId : itemId,
			itemKind : 0,
			itemCount : 1,
			
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0,
			
			time : now
		})).sub(1);
	}
	
	// 부대가 이동하는 기록을 저장합니다.
	function recordMoveArmy(
		
		address owner,
		
		// 위치 정보
		uint fromCol, uint fromRow, uint toCol, uint toRow
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_MOVE_ARMY,
			
			owner : owner,
			enemy : address(0x0),
			
			col : fromCol,
			row : fromRow,
			toCol : toCol,
			toRow : toRow,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0,
			
			time : now
		})).sub(1);
	}
	
	// 승리 기록을 저장합니다.
	function recordWin(
		
		address owner, address enemy,
		
		// 위치 정보
		uint fromCol, uint fromRow, uint toCol, uint toRow,
		
		// 전리품
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_WIN,
			
			owner : owner,
			enemy : enemy,
			
			col : fromCol,
			row : fromRow,
			toCol : toCol,
			toRow : toRow,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 패배 기록을 저장합니다.
	function recordLose(
		
		address owner, address enemy,
		
		// 위치 정보
		uint fromCol, uint fromRow, uint toCol, uint toRow,
		
		// 전리품
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_LOSE,
			
			owner : owner,
			enemy : enemy,
			
			col : fromCol,
			row : fromRow,
			toCol : toCol,
			toRow : toRow,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 원거리 공격 기록을 저장합니다.
	function recordRangedAttack(
		
		address owner, address enemy,
		
		// 위치 정보
		uint fromCol, uint fromRow, uint toCol, uint toRow,
		
		// 돌려받을 자원
		uint wood, uint stone, uint iron, uint ducat
		
	) onlyDelight external returns (uint) {
		
		return history.push(Record({
			kind : RECORD_RANGED_ATTACK,
			
			owner : owner,
			enemy : enemy,
			
			col : fromCol,
			row : fromRow,
			toCol : toCol,
			toRow : toRow,
			
			buildingId : 0,
			buildingKind : 0,
			buildingLevel : 0,
			
			armyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			itemId : 0,
			itemKind : 0,
			itemCount : 0,
			
			wood : wood,
			stone : stone,
			iron : iron,
			ducat : ducat,
			
			time : now
		})).sub(1);
	}
	
	// 부대와 관련된 상세 기록을 추가합니다.
	function addArmyRecordDetail(
		
		uint recordId,
		address owner,
		
		// 부대 정보
		uint armyId, uint unitKind, uint unitCount
		
	) onlyDelight external {
		
		recordIdToDetails[recordId].push(RecordDetail({
			
			owner : owner,
			
			armyId : armyId,
			targetArmyId : 0,
			unitKind : unitKind,
			unitCount : unitCount,
			
			buildingId : 0,
			buildingKind : 0,
			
			enemyWood : 0,
			enemyStone : 0,
			enemyIron : 0,
			enemyDucat : 0
		}));
	}
	
	// 대상 부대와 관련된 상세 기록을 추가합니다.
	function addTargetArmyRecordDetail(
		
		uint recordId,
		address owner,
		
		// 부대 정보
		uint armyId, uint targetArmyId, uint unitKind, uint unitCount
		
	) onlyDelight external {
		
		recordIdToDetails[recordId].push(RecordDetail({
			
			owner : owner,
			
			armyId : armyId,
			targetArmyId : targetArmyId,
			unitKind : unitKind,
			unitCount : unitCount,
			
			buildingId : 0,
			buildingKind : 0,
			
			enemyWood : 0,
			enemyStone : 0,
			enemyIron : 0,
			enemyDucat : 0
		}));
	}
	
	// 건물과 관련된 상세 기록을 추가합니다.
	function addBuildingRecordDetail(
		
		uint recordId,
		address owner,
		
		// 건물 정보
		uint buildingId, uint buildingKind
		
	) onlyDelight external {
		
		recordIdToDetails[recordId].push(RecordDetail({
			
			owner : owner,
			
			armyId : 0,
			targetArmyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			buildingId : buildingId,
			buildingKind : buildingKind,
			
			enemyWood : 0,
			enemyStone : 0,
			enemyIron : 0,
			enemyDucat : 0
		}));
	}
	
	// 적이 돌려받을 자원과 관련된 상세 기록을 추가합니다.
	function addEnemyResourceRecordDetail(
		
		uint recordId,
		address enemy,
		
		// 적이 돌려받을 자원
		uint enemyWood, uint enemyStone, uint enemyIron, uint enemyDucat
		
	) onlyDelight external {
		
		recordIdToDetails[recordId].push(RecordDetail({
			
			owner : enemy,
			
			armyId : 0,
			targetArmyId : 0,
			unitKind : 0,
			unitCount : 0,
			
			buildingId : 0,
			buildingKind : 0,
			
			enemyWood : enemyWood,
			enemyStone : enemyStone,
			enemyIron : enemyIron,
			enemyDucat : enemyDucat
		}));
	}
}