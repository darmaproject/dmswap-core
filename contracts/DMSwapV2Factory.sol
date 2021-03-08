pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './DMSwapV2Pair.sol';
import './libraries/owner.sol';
import './libraries/PairNamer.sol';

contract UniswapV2Factory is IUniswapV2Factory, Ownable {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    mapping(address => address[]) public pairCreater;
    mapping(address => address) public createrPair;
    address[] public allPairs;

    uint8[2] feeWeights = [80, 20];     //redelivery, pair owner

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) Ownable() public {
        feeTo = owner();
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function pairCreaterLength(address account) external view returns (uint) {
        return pairCreater[account].length;
    }

    function getCreaterPairs(address account) public view returns (address[] memory){
        return pairCreater[account];
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        string memory pairName = PairNamerLibrary.pairName(token0,token1);
        string memory pairSymbol = PairNamerLibrary.pairSymbol(token0,token1);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1,pairName,pairSymbol);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);

        createrPair[pair] = tx.origin;
        address[] storage pairs = pairCreater[tx.origin];
        pairs.push(pair);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setFeeWeights(uint8[2] calldata weights) external onlyOwner{
        require(weights[0] + weights[1] == 100, "UniswapV2: INVALID PARAMETER.");
        feeWeights = weights;
    }

    function getFeeWeights() view external returns(uint8[2] memory weights) {
        weights = feeWeights;
    }

    function setPairFeeRatio(address tokenA, address tokenB, uint16 feeRatio) external {
        require(feeRatio>=0 && feeRatio<=50, "UniswapV2: INVALID PARAMETER.");
        address pair = getPairAddress(tokenA, tokenB);
        require(createrPair[pair] == msg.sender, "UniswapV2: INVALID Pair Creater.");

        return IUniswapV2Pair(pair).setFeeRatio(feeRatio);
    }

    function getPairFeeRatio(address tokenA, address tokenB) view external returns(uint16){
        address pair = getPairAddress(tokenA, tokenB);

        return IUniswapV2Pair(pair).getFeeRatio();
    }

    function getCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function getPairAddress(address tokenA, address tokenB) view private returns(address){
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        address pair = getPair[token0][token1];
        
        require(pair != address(0), 'UniswapV2: ZERO_ADDRESS');
        
        return pair;
    }

}
