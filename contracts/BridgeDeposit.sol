pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BridgeDeposit {
    using SafeERC20 for IERC20;

    address public manager;

    event Deposit(address indexed _from, uint _amount);
    event GenTransfer(address indexed _from, uint _amount);
    event TokenTransfer(address indexed _from, uint _amount, address token);

    receive() payable external {
        // Native 토큰 입금만 체크
        // Case 1: Ethereum -> Generation
        // (해당사항 없음)
        // Case 2: Generation -> Ethereum
        // receive 함수에서 체크!

        if (msg.sender != manager) {
            // 0.000001
            uint _minAmount = 1*(10**12);
            require(msg.value >= _minAmount, "You need to send at least 0.000001 GEN");

            emit Deposit(msg.sender, msg.value);
        }
    }

    constructor() { 
        manager = msg.sender;
    }

    function version() public pure returns (string memory) {
        return "0.1.0";
    }

    function name() public pure returns (string memory) {
        return "Bridge Deposit Contract";
    }

    // event for EVM logging
    event ManagerSet(address indexed oldManager, address indexed newManager);

    // modifier to check if caller is manager
    modifier isManager() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == manager, "Caller is not manager");
        _;
    }
    
    function changeManager(address newManager) public isManager {
        emit ManagerSet(manager, newManager);
        manager = newManager;
    }

    function getManager() external view returns (address) {
        return manager;
    }

    // Native
    function getGenBalance() public view returns (uint) {
        return address(this).balance;
    }

    function bridgeGenTransfer(address toAddress, uint256 amount) public isManager {
        // payable(msg.sender).transfer(address(this).balance);
        payable(toAddress).transfer(amount);
        emit GenTransfer(toAddress, amount);
    }

    function getTokenBalance(address token) public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function bridgeTokenTransfer(address toAddress, uint256 amount, address token) public isManager {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalance >= amount, "Insufficient token balance");

        IERC20(token).safeTransfer(toAddress, amount);
        emit TokenTransfer(msg.sender, amount, token);
    }
}