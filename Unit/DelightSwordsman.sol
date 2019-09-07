pragma solidity ^0.5.9;

import "../DelightBaseUnitInterface.sol";
import "../Util/SafeMath.sol";

contract DelightSwordsman is DelightBaseUnitInterface {
	using SafeMath for uint;
	
	Materials private materials = Materials({
		wood : 0,
		stone : 0,
		iron : 200,
		ducat : 100
	});
}