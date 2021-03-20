pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-or-later

import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";
import './interfaces/IERC20.sol';
import './misc/ReentrancyGuard.sol';



contract BasicCredit is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Address for address;


    string public name = "Basic Credit Protocol"; 

    address public Admin;

    address[] public lenders;  //array addresses of lenders

    mapping(address => mapping(address => uint)) public depositBalance;
    mapping(address => bool) public hasDeposited; // has deposited ever?

    address[] public borrowers;  //array addresses of borrowers

    mapping(address => mapping(address => uint)) public loanAmount;
    mapping(address => mapping(address => uint)) public downPayment;
    mapping(address => mapping(address => uint)) public interestRate;
    mapping(address => mapping(address => uint)) public currentPrincipal;
    mapping(address => mapping(address => uint)) public loanTenure;
    mapping(address => mapping(address => uint)) public loanEMI;
    mapping(address => mapping(address => uint)) public disbursedDate;
    mapping(address => mapping(address => uint)) public nextEMIDate;

    mapping(address => mapping(address => uint)) public creditLimit;
    mapping(address => bool) public hasBorrowed; // has borrowed ever?

    mapping(address => bool) public whitelistedToken; //If a ERC20 token is whitelisted


    constructor() {

        Admin = msg.sender;

    }

    function whitelistToken(address _tokenaddress) public {

        require(msg.sender == Admin, "Only Admin can call this function");

        if(_tokenaddress.isContract()) {

            whitelistedToken[_tokenaddress] = true;
        }
    }

    function removeWhitelist(address _tokenaddress) public {

        require(msg.sender == Admin, "Only Admin can call this function");
        require(whitelistedToken[_tokenaddress] == true, "Token not yet whitelisted");

        if(_tokenaddress.isContract()) {

            whitelistedToken[_tokenaddress] = false;
        }
    }


    //Deposit Tokens - For Lenders

    function DepositTokens(address _tokenaddress, uint _amount) public {


        //require amount greater than 0. Require is a function in solidity.
        require(_amount > 0, "Amount cannot be 0");
        require(whitelistedToken[_tokenaddress] == true, "Only deposits of whitelisted tokens are accepted");

        IERC20(_tokenaddress).safeTransferFrom(msg.sender, address(this), _amount);

        //Update deposit balance

        depositBalance[_tokenaddress][msg.sender] = depositBalance[_tokenaddress][msg.sender].add(_amount);

        //Add user to lenders array if they haven't deposited already

        if(!hasDeposited[msg.sender]) {

            lenders.push(msg.sender);
        }

        hasDeposited[msg.sender] = true;


    }



    //Withdraw Tokens - For Lenders

    function WithdrawTokens(address _tokenaddress, uint _amount) public nonReentrant {

        require(_amount > 0, "Amount cannot be 0");
        require(whitelistedToken[_tokenaddress] == true, "Not a whitelisted Token");

        uint balance = depositBalance[_tokenaddress][msg.sender];

        require(balance > 0, "No balance to withdraw");
        require(_amount <= balance, "Deposit is  less than requested Withdraw amount");

        if(balance > 0 && balance >= _amount) {

            IERC20(_tokenaddress).safeTransfer(msg.sender, _amount);

            depositBalance[_tokenaddress][msg.sender] = depositBalance[_tokenaddress][msg.sender].sub(_amount);

        }  

    }


    function setCreditLimit(address _tokenaddress, address _borroweraddress, uint _amount) public {

        require(whitelistedToken[_tokenaddress] == true, "Not a whitelisted Token");
        require(msg.sender == Admin, "Only Admin can call this function");
        require(_amount > 0, "Amount cannot be 0");

        creditLimit[_tokenaddress][_borroweraddress] = _amount;

    }


    //Borrow Tokens - For Borrowers

    function BorrowTokens(address _tokenaddress, uint _amount) public nonReentrant {

        require(_amount > 0, "Amount cannot be 0");
        require(whitelistedToken[_tokenaddress] == true, "Only whitelisted tokens can be borrowed");

        uint pool_balance = IERC20(_tokenaddress).balanceOf(address(this));

        require(pool_balance >= _amount, "Borrowing Suspended temporarily");

        uint limit = creditLimit[_tokenaddress][msg.sender];

        require(limit != 0, "You don't have a Credit Limit");

        uint bAmount = borrowedAmount[_tokenaddress][msg.sender];

        uint totalCredit = bAmount.add(_amount);

        require(totalCredit <= limit, "Requested amount exceeds your Credit Limit");


        IERC20(_tokenaddress).safeTransfer(msg.sender, _amount);

        borrowedAmount[_tokenaddress][msg.sender] = borrowedAmount[_tokenaddress][msg.sender].add(_amount);

        if(!hasBorrowed[msg.sender]) {

            borrowers.push(msg.sender);
        }   

        //Update borrower status

        hasBorrowed[msg.sender] = true;
 
    }


    function emiCalculator(uint _loanAmount, uint _interestRate, uint _loantenure) internal returns(uint) {

        uint monthlyInterestRate = _interestRate / 12 ;
        uint emi = _loanAmount * monthlyInterestRate * ((( 1 + monthlyInterestRate )^_loantenure)/ (((1+monthlyInterestRate)^_loantenure) - 1));
        return emi;

    }


    // function AdvancedBorrow(address _tokenAddress, uint _amount, uint _tenure, uint _emiCycle) public {

    //     require(_amount > 0, "Amount cannot be 0");
    //     require(whitelistedToken[_tokenaddress] == true, "Not a whitelisted token");
    //     require(_tenure <= 6, "Selected tenure not available")
     
    // }


    //Repay Tokens - For Borrowers

    function RepayTokens(address _tokenaddress, uint _amount) public {


        //require amount greater than 0. Require is a function in solidity.
        require(_amount > 0, "Amount cannot be 0");
        require(whitelistedToken[_tokenaddress] == true, "Not a whitelisted token");

        uint bAmount = borrowedAmount[_tokenaddress][msg.sender];

        require(bAmount <= _amount, "Repayment amount greater than current due");


        //Transfer Dai Tokens
        IERC20(_tokenaddress).safeTransferFrom(msg.sender, address(this), _amount);

        //Update borrow balance

        borrowedAmount[_tokenaddress][msg.sender] = borrowedAmount[_tokenaddress][msg.sender].sub(_amount);


    }

}