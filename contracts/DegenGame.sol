// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract DegenGame {
    uint256 public constant BASE_PRICE = 0.001 ether;
    uint256 public constant PRICE_INCREMENT = 0.0001 ether;
    uint256 public constant TIME_EXTENSION = 30 seconds;
    uint256 public constant MAX_TIMER = 24 hours;
    uint256 public constant MAGNITUDE = 2**128;

    uint256 public jackpot;
    uint256 public timerEnd;
    address public lastBuyer;
    uint256 public totalKeys;
    uint256 public keyPrice;
    uint256 public dividendPerKey;
    bool public gameActive;

    mapping(address => uint256) public keysOwned;
    mapping(address => int256) public payoutsTo;

    event KeysPurchased(address indexed buyer, uint256 amount, uint256 cost, uint256 newTimerEnd);
    event DividendsClaimed(address indexed player, uint256 amount);
    event JackpotClaimed(address indexed winner, uint256 amount);

    constructor() {
        keyPrice = BASE_PRICE;
        timerEnd = block.timestamp + MAX_TIMER;
        gameActive = true;
    }

    function getCost(uint256 _amount) public view returns (uint256) {
        // Arithmetic progression sum: N * currentPrice + (N * (N - 1) / 2) * increment
        return (_amount * keyPrice) + ((_amount * (_amount - 1) / 2) * PRICE_INCREMENT);
    }

    function buyKeys(uint256 _amount) public payable {
        require(gameActive, "Game over");
        require(block.timestamp < timerEnd, "Timer expired");
        require(_amount > 0, "Must buy at least 1 key");

        uint256 cost = getCost(_amount);
        require(msg.value >= cost, "Insufficient ETH");

        // Update timer
        timerEnd += _amount * TIME_EXTENSION;
        if (timerEnd > block.timestamp + MAX_TIMER) {
            timerEnd = block.timestamp + MAX_TIMER;
        }

        // Distribute funds (50% jackpot, 50% dividends)
        if (totalKeys == 0) {
            jackpot += cost; // First buyer's funds go entirely to jackpot
        } else {
            uint256 dividends = cost / 2;
            uint256 toJackpot = cost - dividends;
            jackpot += toJackpot;
            dividendPerKey += (dividends * MAGNITUDE) / totalKeys;
        }

        // Update player state
        keysOwned[msg.sender] += _amount;
        payoutsTo[msg.sender] += int256(_amount * dividendPerKey);
        
        // Update global state
        totalKeys += _amount;
        keyPrice += _amount * PRICE_INCREMENT;
        lastBuyer = msg.sender;

        emit KeysPurchased(msg.sender, _amount, cost, timerEnd);

        // Refund excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    function getUnclaimedDividends(address _player) public view returns (uint256) {
        int256 total = int256(keysOwned[_player] * dividendPerKey);
        int256 available = total - payoutsTo[_player];
        if (available < 0) return 0;
        return uint256(available) / MAGNITUDE;
    }

    function claimDividends() public {
        uint256 dividends = getUnclaimedDividends(msg.sender);
        require(dividends > 0, "No dividends available");
        
        payoutsTo[msg.sender] += int256(dividends * MAGNITUDE);
        payable(msg.sender).transfer(dividends);
        
        emit DividendsClaimed(msg.sender, dividends);
    }

    function claimJackpot() public {
        require(gameActive, "Already claimed");
        require(block.timestamp >= timerEnd, "Game still running");
        require(msg.sender == lastBuyer, "Not the winner");

        gameActive = false;
        uint256 amount = jackpot;
        jackpot = 0;
        
        payable(msg.sender).transfer(amount);
        
        emit JackpotClaimed(msg.sender, amount);
    }

    function getGameState() public view returns (
        bool _gameActive,
        uint256 _timerEnd,
        uint256 _jackpot,
        uint256 _totalKeys,
        uint256 _keyPrice,
        address _lastBuyer
    ) {
        return (gameActive, timerEnd, jackpot, totalKeys, keyPrice, lastBuyer);
    }

    function getPlayerInfo(address _player) public view returns (
        uint256 _keysOwned,
        uint256 _unclaimedDividends
    ) {
        return (keysOwned[_player], getUnclaimedDividends(_player));
    }
}
