pragma solidity ^0.5.9;

interface DelightItemInterface {
	
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	
	// 재료 정보
	struct Materials {
		uint wood;
		uint stone;
		uint iron;
		uint ducat;
	}
	
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint);
	function balanceOf(address _owner) external view returns (uint balance);
	function transfer(address _to, uint _value) external payable returns (bool success);
	function transferFrom(address _from, address _to, uint _value) external payable returns (bool success);
	function approve(address _spender, uint _value) external payable returns (bool success);
	function allowance(address _owner, address _spender) external view returns (uint remaining);
}