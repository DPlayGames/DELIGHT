pragma solidity ^0.5.9;

import "./DelightOwnerInterface.sol";
import "./DelightBase.sol";
import "./DelightInterface.sol";
import "./DelightBuildingManagerInterface.sol";
import "./DelightArmyManagerInterface.sol";
import "./Util/NetworkChecker.sol";
import "./Util/SafeMath.sol";

contract DelightOwner is DelightOwnerInterface, DelightBase, NetworkChecker {
	using SafeMath for uint;
	
	DelightInterface private delight;
	DelightBuildingManagerInterface private buildingManager;
	DelightArmyManagerInterface private armyManager;
	
	constructor() NetworkChecker() public {
		
		if (network == Network.Mainnet) {
			//TODO
		}
		
		else if (network == Network.Kovan) {
			delight			= DelightInterface(0x390127B692C87a384C04B824E9D1dD2F2a310Fa2);
			buildingManager	= DelightBuildingManagerInterface(0xb28D186A960c1b1b8512D4e13a76e33A04F07De4);
			armyManager		= DelightArmyManagerInterface(0xB2DD2E6eC73e394366866FF2E9B7bb1893D986a8);
		}
		
		else if (network == Network.Ropsten) {
			//TODO
		}
		
		else if (network == Network.Rinkeby) {
			//TODO
		}
		
		else {
			revert();
		}
	}
	
	// Gets the record IDs of the owner.
	// 소유주의 기록 ID들을 가져옵니다.
	function getRecordIds(address owner) view external returns (uint[] memory) {
		
		uint recordCount = 0;
		
		for (uint i = 0; i < delight.getRecordCount(); i += 1) {
			
			(
				,
				address account,
				address enemy,
				,
				,
				,
				,
				,
				,
				,
				
			) = delight.getRecord(i);
			
			if (account == owner || enemy == owner) {
				recordCount += 1;
			}
		}
		
		uint[] memory recordIds = new uint[](recordCount);
		uint j = 0;
		
		for (uint i = 0; i < delight.getRecordCount(); i += 1) {
			
			(
				,
				address account,
				address enemy,
				,
				,
				,
				,
				,
				,
				,
				
			) = delight.getRecord(i);
			
			if (account == owner || enemy == owner) {
				recordIds[j] = i;
				j += 1;
			}
		}
		
		return recordIds;
	}
	
	// Gets the building IDs of the owner.
	// 소유주의 건물 ID들을 가져옵니다.
	function getBuildingIds(address owner) view external returns (uint[] memory) {
		
		uint buildingCount = 0;
		
		for (uint i = 0; i < buildingManager.getBuildingCount(); i += 1) {
			
			(
				,
				,
				,
				,
				address buildingOwner,
				
			) = buildingManager.getBuildingInfo(i);
			
			if (buildingOwner == owner) {
				buildingCount += 1;
			}
		}
		
		uint[] memory buildingIds = new uint[](buildingCount);
		uint j = 0;
		
		for (uint i = 0; i < buildingManager.getBuildingCount(); i += 1) {
			
			(
				,
				,
				,
				,
				address buildingOwner,
				
			) = buildingManager.getBuildingInfo(i);
			
			if (buildingOwner == owner) {
				buildingIds[j] = i;
				j += 1;
			}
		}
		
		return buildingIds;
	}
	
	// Gets the Army IDs of the owner.
	// 소유주의 부대 ID들을 가져옵니다.
	function getArmyIds(address owner) view external returns (uint[] memory) {
		
		uint armyCount = 0;
		
		for (uint i = 0; i < armyManager.getArmyCount(); i += 1) {
			
			(
				,
				,
				,
				,
				,
				address armyOwner,
				
			) = armyManager.getArmyInfo(i);
			
			if (armyOwner == owner) {
				armyCount += 1;
			}
		}
		
		uint[] memory armyIds = new uint[](armyCount);
		uint j = 0;
		
		for (uint i = 0; i < armyManager.getArmyCount(); i += 1) {
			
			(
				,
				,
				,
				,
				,
				address armyOwner,
				
			) = armyManager.getArmyInfo(i);
			
			if (armyOwner == owner) {
				armyIds[j] = i;
				j += 1;
			}
		}
		
		return armyIds;
	}
	
	// 전체 맵의 건물 소유주 목록을 반환합니다.
	function getMapBuildingOwners() view external returns (address[] memory) {
		
		address[] memory owners = new address[](ROW_RANGE * COL_RANGE);
		
		for (uint row = 0; row < ROW_RANGE; row += 1) {
			for (uint col = 0; col < COL_RANGE; col += 1) {
				owners[row * COL_RANGE + col] = buildingManager.getPositionBuildingOwner(col, row);
			}
		}
		
		return owners;
	}
	
	// 전체 맵의 부대 소유주 목록을 반환합니다.
	function getMapArmyOwners() view external returns (address[] memory) {
		
		address[] memory owners = new address[](ROW_RANGE * COL_RANGE);
		
		for (uint row = 0; row < ROW_RANGE; row += 1) {
			for (uint col = 0; col < COL_RANGE; col += 1) {
				owners[row * COL_RANGE + col] = armyManager.getPositionOwner(col, row);
			}
		}
		
		return owners;
	}
}
