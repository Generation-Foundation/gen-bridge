pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bridge {
    using SafeMath for uint256;
    IERC20 token;

    address public manager;

    constructor() { 
        manager = msg.sender;
    }

    function version() public pure returns (string memory) {
        return "0.1.0";
    }

    function name() public pure returns (string memory) {
        return "Generation Bridge";
    }

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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

    mapping(address => GateKeeper) public gateKeeperMap;
    struct GateKeeper {
        address nodeAddress;
        address rewardAddress;
        string name;
        string website;
        string description;
        uint256 commissionRate;
        uint256 maximumCommission;
        bool valid;
    }

    function createGateKeeper(
        address _rewardAddress,
        string memory _name,
        string memory _website,
        string memory _description,
        uint256 _commissionRate,
        uint256 _maximumCommission
    ) public {
        // 이미 존재하는 GK 인가?
        require(!gateKeeperMap[msg.sender].valid, "Already exists");
        
        gateKeeperMap[msg.sender] = GateKeeper(
            msg.sender,
            _rewardAddress,
            _name,
            _website,
            _description,
            _commissionRate,
            _maximumCommission,
            true
        );
    }

    function updateGateKeeper(
        address _rewardAddress,
        string memory _name,
        string memory _website,
        string memory _description,
        uint256 _commissionRate,
        uint256 _maximumCommission
    ) public {
        require(gateKeeperMap[msg.sender].valid, "The Gate Keeper Not found");
        
        gateKeeperMap[msg.sender] = GateKeeper(
            msg.sender,
            _rewardAddress,
            _name,
            _website,
            _description,
            _commissionRate,
            _maximumCommission,
            true
        );
    }

    function deleteGateKeeper() public {
        require(gateKeeperMap[msg.sender].valid, "The Gate Keeper Not found");

        delete gateKeeperMap[msg.sender];
    }

    // key: txhash
    mapping(bytes32 => Report[]) public reportMap;
    struct Report {
        address gateKeeperAdminAddress;
        address userAddress;
        uint256 lockAmount;
        string fromChain;
        address fromTokenAddress;
        string toChain;
        address toTokenAddress;
    }

    // keyA => mapping(keyB => value)
    mapping(bytes32 => mapping(address => bool)) public reportKeyMap;
    // keyA push
    bytes32[] reportedTxhash;
    // master gate keeper 가 trnasfer 처리한 txhash
    mapping(bytes32 => bool) public completedKeyMap;
    // bytes32[] completedTxhash;

    function createReport(
        bytes32 _txhash,
        address _userAddress,
        uint256 _lockAmount,
        string memory _fromChain,
        address _fromTokenAddress,
        string memory _toChain,
        address _toTokenAddress
    ) public {
        require(gateKeeperMap[msg.sender].valid, "The Gate Keeper Not found");

        require(!(reportKeyMap[_txhash])[msg.sender], "Only one time call is allowed by each Gate Keeper");
        (reportKeyMap[_txhash])[msg.sender] = true;

        reportedTxhash.push(_txhash);

        reportMap[_txhash].push(
            Report (
                msg.sender,
                _userAddress,
                _lockAmount,
                _fromChain,
                _fromTokenAddress,
                _toChain,
                _toTokenAddress
            )
        );
    }

    function getLatestReport() public view returns (uint256) {
        return reportedTxhash.length - 1;
    }

    function setCompletedReport(bytes32 _txhash) public isManager {
        require(!completedKeyMap[_txhash], "Only one time call is allowed for txhash");
        completedKeyMap[_txhash] = true;

        emit BridgeTransfer(
            (reportMap[_txhash])[0].userAddress,
            (reportMap[_txhash])[0].lockAmount,
            (reportMap[_txhash])[0].fromChain,
            (reportMap[_txhash])[0].fromTokenAddress,
            (reportMap[_txhash])[0].toChain,
            (reportMap[_txhash])[0].toTokenAddress
        );
    }

    function getCompletedReport(bytes32 _txhash) public view returns (bool) {
        // true means transfered txhash.
        return completedKeyMap[_txhash];
    }

    event BridgeTransfer(
        address indexed userAddress,
        uint256 lockAmount,
        string fromChain,
        address fromTokenAddress,
        string toChain,
        address toTokenAddress
    );
}