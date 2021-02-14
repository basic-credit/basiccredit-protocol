pragma solidity >=0.6.0 <0.8.0;


import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract TDai is ERC20 {

	address public Admin;


	constructor() public ERC20("TDai","TDai") {
		Admin = msg.sender;		
	}

	function MintToken(address _to, uint _amount) public {
		require(msg.sender == Admin, "Only Admin can call this function");
		_mint(_to, _amount);

	}

}