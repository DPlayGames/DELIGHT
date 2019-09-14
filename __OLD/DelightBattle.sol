pragma solidity ^0.5.9;

import "./DelightWorldInterface.sol";
import "./DelightSub.sol";
import "./Util/SafeMath.sol";

// 전투 관련 처리
contract DelightBattle is DelightSub {
	using SafeMath for uint;
	
	// 기사의 기본 버프
	uint constant internal KNIGHT_DEFAULT_BUFF_HP = 10;
	uint constant internal KNIGHT_DEFAULT_BUFF_DAMAGE = 5;
	
	DelightWorldInterface private delightWorld;
	
	constructor() DelightSub() public {
		
		// DPlay History 스마트 계약을 불러옵니다.
		if (network == Network.Mainnet) {
			//TODO
		} else if (network == Network.Kovan) {
			//TODO
			delightWorld = DelightWorldInterface(0x0);
		} else if (network == Network.Ropsten) {
			//TODO
		} else if (network == Network.Rinkeby) {
			//TODO
		} else {
			revert();
		}
	}
	
	
		// 거리 계산
		uint distance = (fromCol < toCol ? toCol - fromCol : fromCol - toCol) + (fromRow < toRow ? toRow - fromRow : fromRow - toRow);
		
		uint[] storage armyIds = positionToArmyIds[fromCol][fromRow];
		uint[] storage enemyArmyIds = positionToArmyIds[toCol][toRow];
		
		enemyArmyIds.length = UNIT_KIND_COUNT;
		
		uint totalDamage = 0;
		uint totalEnemyDamage = 0;
		
		// 총 공격력을 계산합니다.
		for (uint i = 0; i < UNIT_KIND_COUNT; i += 1) {
			
			Army memory army = armies[armyIds[i]];
			
			if (
			// 유닛의 개수가 0개 이상이어야 합니다.
			army.unitCount > 0 &&
			
			// 이동이 가능한 거리인지 확인합니다.
			distance <= units[army.unitKind].movableDistance) {
				
				// 아군의 공격력 추가
				totalDamage = totalDamage.add(
					units[army.unitKind].damage.add(
						
						// 기사인 경우 기사 아이템의 공격력을 추가합니다.
						i == UNIT_KNIGHT ? knightItem.getItemDamage(army.knightItemId) : (
							
							// 기사가 아닌 경우 기사의 버프 데미지를 추가합니다.
							armyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_DAMAGE + knightItem.getItemBuffDamage(armies[armyIds[UNIT_KNIGHT]].knightItemId) : 0
						)
						
					).mul(army.unitCount)
				);
			}
			
			Army memory enemyArmy = armies[enemyArmyIds[i]];
			
			// 유닛의 개수가 0개 이상이어야 합니다.
			if (enemyArmy.unitCount > 0) {
				
				// 적군의 공격력 추가
				totalEnemyDamage = totalEnemyDamage.add(
					units[enemyArmy.unitKind].damage.add(
						
						// 기사인 경우 기사 아이템의 공격력을 추가합니다.
						i == UNIT_KNIGHT ? knightItem.getItemDamage(enemyArmy.knightItemId) : (
							
							// 기사가 아닌 경우 기사의 버프 데미지를 추가합니다.
							enemyArmyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_DAMAGE + knightItem.getItemBuffDamage(armies[enemyArmyIds[UNIT_KNIGHT]].knightItemId) : 0
						)
						
					).mul(enemyArmy.unitCount)
				);
			}
		}
		
		// 전리품
		Material memory rewardMaterial = Material({
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0
		});
		
		// 전투를 개시합니다.
		for (uint i = 0; i < UNIT_KIND_COUNT; i += 1) {
			
			// 적군이 아군을 공격합니다.
			Army storage army = armies[armyIds[i]];
			
			if (
			// 유닛의 개수가 0개 이상이어야 합니다.
			army.unitCount > 0 &&
			
			// 이동이 가능한 거리인지 확인합니다.
			distance <= units[army.unitKind].movableDistance) {
				
				// 아군의 체력을 계산합니다.
				uint armyHP = units[army.unitKind].hp.add(
					
					// 기사인 경우 기사 아이템의 HP를 추가합니다.
					i == UNIT_KNIGHT ? knightItem.getItemHP(army.knightItemId) : (
						
						// 기사가 아닌 경우 기사의 버프 HP를 추가합니다.
						armyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_HP + knightItem.getItemBuffHP(armies[armyIds[UNIT_KNIGHT]].knightItemId) : 0
					)
					
				).mul(army.unitCount);
				
				armyHP = armyHP <= totalEnemyDamage ? 0 : armyHP.sub(totalEnemyDamage);
				
				// 전투 결과를 계산합니다.
				uint remainUnitCount = armyHP.add(armyHP % units[army.unitKind].hp).div(units[army.unitKind].hp);
				uint deadUnitCount = army.unitCount.sub(remainUnitCount);
				
				// 적의 총 공격력을 낮춥니다.
				totalEnemyDamage = totalEnemyDamage <= deadUnitCount.mul(units[army.unitKind].hp) ? 0 : totalEnemyDamage.sub(deadUnitCount.mul(units[army.unitKind].hp));
				
				// 전리품을 계산합니다.
				Material memory unitMaterial = unitMaterials[army.unitKind];
				rewardMaterial.wood = rewardMaterial.wood.add(unitMaterial.wood.mul(deadUnitCount));
				rewardMaterial.stone = rewardMaterial.wood.add(unitMaterial.stone.mul(deadUnitCount));
				rewardMaterial.iron = rewardMaterial.wood.add(unitMaterial.iron.mul(deadUnitCount));
				rewardMaterial.ducat = rewardMaterial.wood.add(unitMaterial.ducat.mul(deadUnitCount));
				
				// 남은 병사 숫자를 저장합니다.
				army.unitCount = remainUnitCount;
				if (army.unitCount == 0) {
					army.owner = address(0x0);
				}
				
				// 상세 기록을 저장합니다.
				delightHistory.addArmyRecordDetail(
					delightHistory.getRecordCount(),
					owner,
					armyIds[i],
					army.unitKind,
					deadUnitCount
				);
				
				// 이벤트 발생
				emit DeadUnits(owner, armyIds[i], deadUnitCount);
			}
			
			// 아군이 적군을 공격합니다.
			Army storage enemyArmy = armies[enemyArmyIds[i]];
			
			// 유닛의 개수가 0개 이상이어야 합니다.
			if (enemyArmy.unitCount > 0) {
				
				// 적군의 체력을 계산합니다.
				uint ememyArmyHP = units[enemyArmy.unitKind].hp.add(
					
					// 기사인 경우 기사 아이템의 HP를 추가합니다.
					i == UNIT_KNIGHT ? knightItem.getItemHP(enemyArmy.knightItemId) : (
						
						// 기사가 아닌 경우 기사의 버프 HP를 추가합니다.
						enemyArmyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_HP + knightItem.getItemBuffHP(armies[enemyArmyIds[UNIT_KNIGHT]].knightItemId) : 0
					)
					
				).mul(enemyArmy.unitCount);
				
				ememyArmyHP = ememyArmyHP <= totalDamage ? 0 : ememyArmyHP.sub(totalDamage);
				
				// 전투 결과를 계산합니다.
				uint remainEnemyUnitCount = ememyArmyHP.add(ememyArmyHP % units[enemyArmy.unitKind].hp).div(units[enemyArmy.unitKind].hp);
				uint deadEnemyUnitCount = enemyArmy.unitCount.sub(remainEnemyUnitCount);
				
				// 아군의 총 공격력을 낮춥니다.
				totalDamage = totalDamage <= deadEnemyUnitCount.mul(units[enemyArmy.unitKind].hp) ? 0 : totalDamage.sub(deadEnemyUnitCount.mul(units[enemyArmy.unitKind].hp));
				
				// 전리품을 계산합니다.
				Material memory unitMaterial = unitMaterials[enemyArmy.unitKind];
				rewardMaterial.wood = rewardMaterial.wood.add(unitMaterial.wood.mul(deadEnemyUnitCount));
				rewardMaterial.stone = rewardMaterial.wood.add(unitMaterial.stone.mul(deadEnemyUnitCount));
				rewardMaterial.iron = rewardMaterial.wood.add(unitMaterial.iron.mul(deadEnemyUnitCount));
				rewardMaterial.ducat = rewardMaterial.wood.add(unitMaterial.ducat.mul(deadEnemyUnitCount));
				
				// 남은 병사 숫자를 저장합니다.
				enemyArmy.unitCount = remainEnemyUnitCount;
				if (enemyArmy.unitCount == 0) {
					enemyArmy.owner = address(0x0);
				}
				
				// 상세 기록을 저장합니다.
				delightHistory.addArmyRecordDetail(
					delightHistory.getRecordCount(),
					enemy,
					enemyArmyIds[i],
					enemyArmy.unitKind,
					deadEnemyUnitCount
				);
				
				// 이벤트 발생
				emit DeadUnits(enemy, enemyArmyIds[i], deadEnemyUnitCount);
			}
		}
		
		// 승리
		if (totalDamage >= totalEnemyDamage) {
			
			enemyArmyIds.length = UNIT_KIND_COUNT;
			
			// 승리하면 병력을 이동합니다.
			for (uint i = 0; i < UNIT_KIND_COUNT; i += 1) {
				
				Army memory army = armies[armyIds[i]];
				
				if (
				// 유닛의 개수가 0개 이상이어야 합니다.
				army.unitCount > 0 &&
				
				// 이동이 가능한 거리인지 확인합니다.
				distance <= units[army.unitKind].movableDistance) {
					
					enemyArmyIds[i] = armyIds[i];
					
					delete armyIds[i];
				}
			}
			
			// 만약 건물이 존재하면, 건물을 파괴합니다.
			if (positionToBuildingId[toCol][toRow] != 0) {
				
				uint buildingKind = buildings[positionToBuildingId[toCol][toRow]].kind;
				
				// 전리품을 추가합니다.
				Material memory buildingMaterial = buildingMaterials[buildingKind];
				rewardMaterial.wood = rewardMaterial.wood.add(buildingMaterial.wood);
				rewardMaterial.stone = rewardMaterial.wood.add(buildingMaterial.stone);
				rewardMaterial.iron = rewardMaterial.wood.add(buildingMaterial.iron);
				rewardMaterial.ducat = rewardMaterial.wood.add(buildingMaterial.ducat);
				
				// 본부인 경우, 본부 목록에서 제거합니다.
				if (buildingKind == BUILDING_HQ) {
					
					uint[] storage hqIds = ownerToHQIds[enemy];
					
					for (uint i = hqIds.length - 1; i > 0; i -= 1) {
						
						if (hqIds[i - 1] == positionToBuildingId[toCol][toRow]) {
							hqIds[i - 1] = hqIds[i];
							break;
						} else {
							hqIds[i - 1] = hqIds[i];
						}
					}
					
					hqIds.length -= 1;
				}
				
				// 건물을 파괴합니다.
				delete buildings[positionToBuildingId[toCol][toRow]];
				delete positionToBuildingId[toCol][toRow];
				
				// 상세 기록을 저장합니다.
				delightHistory.addBuildingRecordDetail(
					delightHistory.getRecordCount(),
					enemy,
					positionToBuildingId[toCol][toRow],
					buildingKind
				);
				
				// 이벤트 발생
				emit DestroyBuilding(enemy, positionToBuildingId[toCol][toRow], buildingKind, toCol, toRow);
			}
			
			// 전리품을 취득합니다.
			wood.transferFrom(address(this), owner, rewardMaterial.wood);
			stone.transferFrom(address(this), owner, rewardMaterial.stone);
			iron.transferFrom(address(this), owner, rewardMaterial.iron);
			ducat.transferFrom(address(this), owner, rewardMaterial.ducat);
			
			// 기록을 저장합니다.
			delightHistory.recordWin(owner, enemy, fromCol, fromRow, toCol, toRow, rewardMaterial.wood, rewardMaterial.stone, rewardMaterial.iron, rewardMaterial.ducat);
			
			// 이벤트 발생
			emit Win(owner, enemy, fromCol, fromRow, toCol, toRow, rewardMaterial.wood, rewardMaterial.stone, rewardMaterial.iron, rewardMaterial.ducat);
		}
		
		// 패배
		else {
			
			// 패배하면 상대방이 전리품을 취득합니다.
			wood.transferFrom(address(this), enemy, rewardMaterial.wood);
			stone.transferFrom(address(this), enemy, rewardMaterial.stone);
			iron.transferFrom(address(this), enemy, rewardMaterial.iron);
			ducat.transferFrom(address(this), enemy, rewardMaterial.ducat);
			
			// 기록을 저장합니다.
			delightHistory.recordLose(owner, enemy, fromCol, fromRow, toCol, toRow, rewardMaterial.wood, rewardMaterial.stone, rewardMaterial.iron, rewardMaterial.ducat);
			
			// 이벤트 발생
			emit Lose(owner, enemy, fromCol, fromRow, toCol, toRow, rewardMaterial.wood, rewardMaterial.stone, rewardMaterial.iron, rewardMaterial.ducat);
		}
	
	/*
	// 원거리 유닛으로 특정 지역을 공격합니다.
	function rangedAttack(
		address owner,
		uint fromCol, uint fromRow,
		uint toCol, uint toRow
	) onlyDelight checkRange(fromCol, fromRow) checkRange(toCol, toRow) external {
		
		// 부대의 소유주를 확인합니다.
		require(getArmyOwnerByPosition(fromCol, fromRow) == owner);
		
		address targetArmyOwner = getArmyOwnerByPosition(toCol, toRow);
		
		// 아군을 공격할 수 없습니다.
		require(targetArmyOwner != owner);
		
		// 거리 계산
		uint distance = (fromCol < toCol ? toCol - fromCol : fromCol - toCol) + (fromRow < toRow ? toRow - fromRow : fromRow - toRow);
		
		uint[] storage armyIds = positionToArmyIds[fromCol][fromRow];
		uint[] storage targetArmyIds = positionToArmyIds[toCol][toRow];
		
		uint totalDamage = 0;
		uint totalEnemyDamage = 0;
		
		// 돌려받을 자원
		Material memory returnMaterial = Material({
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0
		});
		
		// 적이 돌려받을 자원
		Material memory enemyReturnMaterial = Material({
			wood : 0,
			stone : 0,
			iron : 0,
			ducat : 0
		});
		
		// 총 공격력을 계산합니다.
		for (uint i = 0; i < UNIT_KIND_COUNT; i += 1) {
			
			Army memory army = armies[armyIds[i]];
			
			if (
			// 유닛의 개수가 0개 이상이어야 합니다.
			armyUnitCount > 0 &&
			
			// 공격이 가능한 거리인지 확인합니다.
			distance <= units[armyUnitKind].attackableDistance) {
				
				// 아군의 공격력 추가
				totalDamage = totalDamage.add(
					units[armyUnitKind].damage.add(
						
						// 기사인 경우 기사 아이템의 공격력을 추가합니다.
						i == UNIT_KNIGHT ? knightItem.getItemDamage(army.knightItemId) : (
							
							// 기사가 아닌 경우 기사의 버프 데미지를 추가합니다.
							armyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_DAMAGE + knightItem.getItemBuffDamage(armies[armyIds[UNIT_KNIGHT]].knightItemId) : 0
						)
						
					).mul(armyUnitCount)
				);
			}
			
			Army memory enemyArmy = armies[targetArmyIds[i]];
			
			if (
			// 유닛의 개수가 0개 이상이어야 합니다.
			enemyArmyUnitCount > 0 &&
			
			// 공격이 가능한 거리인지 확인합니다.
			distance <= units[enemyArmyUnitKind].attackableDistance) {
				
				// 적군의 공격력 추가
				totalEnemyDamage = totalEnemyDamage.add(
					units[enemyArmyUnitKind].damage.add(
						
						// 기사인 경우 기사 아이템의 공격력을 추가합니다.
						i == UNIT_KNIGHT ? knightItem.getItemDamage(enemyArmy.knightItemId) : (
							
							// 기사가 아닌 경우 기사의 버프 데미지를 추가합니다.
							targetArmyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_DAMAGE + knightItem.getItemBuffDamage(armies[targetArmyIds[UNIT_KNIGHT]].knightItemId) : 0
						)
						
					).mul(enemyArmyUnitCount)
				);
			}
		}
		
		// 전투를 개시합니다.
		for (uint i = 0; i < UNIT_KIND_COUNT; i += 1) {
			
			// 적군이 아군을 공격합니다.
			Army storage army = armies[armyIds[i]];
			
			// 유닛의 개수가 0개 이상이어야 합니다.
			if (armyUnitCount > 0) {
				
				// 아군의 체력을 계산합니다.
				uint armyHP = units[armyUnitKind].hp.add(
					
					// 기사인 경우 기사 아이템의 HP를 추가합니다.
					i == UNIT_KNIGHT ? knightItem.getItemHP(army.knightItemId) : (
						
						// 기사가 아닌 경우 기사의 버프 HP를 추가합니다.
						armyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_HP + knightItem.getItemBuffHP(armies[armyIds[UNIT_KNIGHT]].knightItemId) : 0
					)
					
				).mul(armyUnitCount);
				
				armyHP = armyHP <= totalEnemyDamage ? 0 : armyHP.sub(totalEnemyDamage);
				
				// 전투 결과를 계산합니다.
				uint remainUnitCount = armyHP.add(armyHP % units[armyUnitKind].hp).div(units[armyUnitKind].hp);
				uint deadUnitCount = armyUnitCount.sub(remainUnitCount);
				
				// 적의 총 공격력을 낮춥니다.
				totalEnemyDamage = totalEnemyDamage <= deadUnitCount.mul(units[armyUnitKind].hp) ? 0 : totalEnemyDamage.sub(deadUnitCount.mul(units[armyUnitKind].hp));
				
				// 돌려받을 자원을 계산합니다.
				returnMaterial.wood = returnMaterial.wood.add(unitMaterials[armyUnitKind].wood.mul(deadUnitCount));
				returnMaterial.stone = returnMaterial.wood.add(unitMaterials[armyUnitKind].stone.mul(deadUnitCount));
				returnMaterial.iron = returnMaterial.wood.add(unitMaterials[armyUnitKind].iron.mul(deadUnitCount));
				returnMaterial.ducat = returnMaterial.wood.add(unitMaterials[armyUnitKind].ducat.mul(deadUnitCount));
				
				// 남은 병사 숫자를 저장합니다.
				armyUnitCount = remainUnitCount;
				if (armyUnitCount == 0) {
					army.owner = address(0x0);
				}
				
				// 상세 기록을 저장합니다.
				delightHistory.addArmyRecordDetail(
					delightHistory.getRecordCount(),
					owner,
					armyIds[i],
					armyUnitKind,
					deadUnitCount
				);
				
				// 이벤트 발생
				emit DeadUnits(owner, armyIds[i], deadUnitCount);
			}
			
			// 아군이 적군을 공격합니다.
			
			// 유닛의 개수가 0개 이상이어야 합니다.
			if (armies[targetArmyIds[i]].unitCount > 0) {
				
				// 적군의 체력을 계산합니다.
				uint ememyArmyHP = units[armies[targetArmyIds[i]].unitKind].hp.add(
					
					// 기사인 경우 기사 아이템의 HP를 추가합니다.
					i == UNIT_KNIGHT ? knightItem.getItemHP(armies[targetArmyIds[i]].knightItemId) : (
						
						// 기사가 아닌 경우 기사의 버프 HP를 추가합니다.
						targetArmyIds[UNIT_KNIGHT] != 0 == true ? KNIGHT_DEFAULT_BUFF_HP + knightItem.getItemBuffHP(armies[targetArmyIds[UNIT_KNIGHT]].knightItemId) : 0
					)
					
				).mul(armies[targetArmyIds[i]].unitCount);
				
				ememyArmyHP = ememyArmyHP <= totalDamage ? 0 : ememyArmyHP.sub(totalDamage);
				
				// 전투 결과를 계산합니다.
				uint remainEnemyUnitCount = ememyArmyHP.add(ememyArmyHP % units[armies[targetArmyIds[i]].unitKind].hp).div(units[armies[targetArmyIds[i]].unitKind].hp);
				uint deadEnemyUnitCount = armies[targetArmyIds[i]].unitCount.sub(remainEnemyUnitCount);
				
				// 아군의 총 공격력을 낮춥니다.
				totalDamage = totalDamage <= deadEnemyUnitCount.mul(units[armies[targetArmyIds[i]].unitKind].hp) ? 0 : totalDamage.sub(deadEnemyUnitCount.mul(units[armies[targetArmyIds[i]].unitKind].hp));
				
				// 돌려받을 자원을 계산합니다.
				enemyReturnMaterial.wood = enemyReturnMaterial.wood.add(unitMaterials[armies[targetArmyIds[i]].unitKind].wood.mul(deadEnemyUnitCount));
				enemyReturnMaterial.stone = enemyReturnMaterial.wood.add(unitMaterials[armies[targetArmyIds[i]].unitKind].stone.mul(deadEnemyUnitCount));
				enemyReturnMaterial.iron = enemyReturnMaterial.wood.add(unitMaterials[armies[targetArmyIds[i]].unitKind].iron.mul(deadEnemyUnitCount));
				enemyReturnMaterial.ducat = enemyReturnMaterial.wood.add(unitMaterials[armies[targetArmyIds[i]].unitKind].ducat.mul(deadEnemyUnitCount));
				
				// 남은 병사 숫자를 저장합니다.
				armies[targetArmyIds[i]].unitCount = remainEnemyUnitCount;
				if (armies[targetArmyIds[i]].unitCount == 0) {
					armies[targetArmyIds[i]].owner = address(0x0);
				}
				
				// 상세 기록을 저장합니다.
				delightHistory.addArmyRecordDetail(
					delightHistory.getRecordCount(),
					targetArmyOwner,
					targetArmyIds[i],
					armies[targetArmyIds[i]].unitKind,
					deadEnemyUnitCount
				);
				
				// 이벤트 발생
				emit DeadUnits(targetArmyOwner, targetArmyIds[i], deadEnemyUnitCount);
			}
		}
		
		// 자원을 돌려받습니다.
		wood.transferFrom(address(this), owner, returnMaterial.wood);
		stone.transferFrom(address(this), owner, returnMaterial.stone);
		iron.transferFrom(address(this), owner, returnMaterial.iron);
		ducat.transferFrom(address(this), owner, returnMaterial.ducat);
		
		wood.transferFrom(address(this), targetArmyOwner, enemyReturnMaterial.wood);
		stone.transferFrom(address(this), targetArmyOwner, enemyReturnMaterial.stone);
		iron.transferFrom(address(this), targetArmyOwner, enemyReturnMaterial.iron);
		ducat.transferFrom(address(this), targetArmyOwner, enemyReturnMaterial.ducat);
		
		// 상세 기록을 저장합니다.
		delightHistory.addEnemyResourceRecordDetail(
			delightHistory.getRecordCount(),
			targetArmyOwner,
			enemyReturnMaterial.wood, enemyReturnMaterial.stone, enemyReturnMaterial.iron, enemyReturnMaterial.ducat
		);
		
		// 기록을 저장합니다.
		delightHistory.recordRangedAttack(owner, targetArmyOwner, fromCol, fromRow, toCol, toRow, returnMaterial.wood, returnMaterial.stone, returnMaterial.iron, returnMaterial.ducat);
		
		// 이벤트 발생
		emit RangedAttack(owner, targetArmyOwner, fromCol, fromRow, toCol, toRow, returnMaterial.wood, returnMaterial.stone, returnMaterial.iron, returnMaterial.ducat, enemyReturnMaterial.wood, enemyReturnMaterial.stone, enemyReturnMaterial.iron, enemyReturnMaterial.ducat);
	}*/
}