pragma solidity >=0.6.0 <0.8.0;


//import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "./TDai.sol";


contract BasicCredit {


	string public name = "Basic Credit Protocol"; 

	address public Admin;

	TDai public tdai;



	address[] public lenders;  //array addresses of lenders

	mapping(address => uint) public depositBalance;
	mapping(address => bool) public hasDeposited; // has deposited ever?
	mapping(address => bool) public isDeposited; // is an active depositer?

	address[] public borrowers;  //array addresses of borrowers

	mapping(address => uint) public borrowedAmount;
	mapping(address => uint) public creditLimit;
	mapping(address => bool) public hasBorrowed; // has borrowed ever?
	mapping(address => bool) public isBorrower; // is an active borrower?


	constructor(TDai _tdai) public {

		tdai = _tdai;    //assigning test Dai contract address
		Admin = msg.sender;


	}


	//Deposit Tokens - For Lenders

	function DepositTokens(uint _amount) public {


		//require amount greater than 0. Require is a function in solidity.
		require(_amount > 0, "Amount cannot be 0");


		//Transfer Dai Tokens
		tdai.transferFrom(msg.sender, address(this), _amount);

		//Update deposit balance

		depositBalance[msg.sender] = depositBalance[msg.sender] + _amount;

		//Add user to lenders array if they haven't deposited already

		if(!hasDeposited[msg.sender]) {

			lenders.push(msg.sender);
		}

		//Update deposit status

		isDeposited[msg.sender] = true;
		hasDeposited[msg.sender] = true;


	}



	//Withdraw Tokens - For Lenders

	function WithdrawTokens(uint _amount) public {

		require(_amount > 0, "Amount cannot be 0");



		uint balance = depositBalance[msg.sender];

		require(balance > 0, "No balance to withdraw");
		require(_amount <= balance, "Deposit is  less than requested Withdraw amount");

		if(balance > 0 && balance >= _amount) {

			tdai.transfer(msg.sender, _amount);

			depositBalance[msg.sender] = depositBalance[msg.sender] - _amount;

			if(depositBalance[msg.sender] == 0) {

				isDeposited[msg.sender] = false;
			}

		}  

	}


	//Borrow Tokens - For Borrowers

	function BorrowTokens(uint _amount) public {

		require(_amount > 0, "Amount cannot be 0");


		uint bAmount = borrowedAmount[msg.sender];
		uint limit = creditLimit[msg.sender];

		uint totalCredit = bAmount + _amount;

		require(totalCredit <= limit, "Credit limit exceeded");

		if(totalCredit <= limit) {

			tdai.transfer(msg.sender, _amount);

			borrowedAmount[msg.sender] = borrowedAmount[msg.sender] + _amount;

			if(!hasBorrowed[msg.sender]) {

				borrowers.push(msg.sender);
			}	

			//Update borrower status

			isBorrower[msg.sender] = true;
			hasBorrowed[msg.sender] = true;

		}  

	}


	//Repay Tokens - For Borrowers

	function RepayTokens(uint _amount) public {


		//require amount greater than 0. Require is a function in solidity.
		require(_amount > 0, "Amount cannot be 0");

		uint bAmount = borrowedAmount[msg.sender];

		require(bAmount <= _amount, "Repayment amount greater than current due");


		//Transfer Dai Tokens
		tdai.transferFrom(msg.sender, address(this), _amount);

		//Update borrow balance

		borrowedAmount[msg.sender] = borrowedAmount[msg.sender] + _amount;

		//If total borrowed amount is repaid then remove from active borrower list

		if(borrowedAmount[msg.sender] == 0) {

			isBorrower[msg.sender] = false;
		}


	}





}