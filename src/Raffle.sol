// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error Raffle__NotEnoughEthSent();
error Raffle__TransferFailed();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded();

/// @title Raffle Lottery
/// @author Favour Aniogor
/// @notice A Simple Raffle Lottery Smart Contract
/// @dev implements chainlink vrf and automation

contract Raffle is VRFConsumerBaseV2 {
    //Type Declaration
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //State Variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 3;

    uint256 private immutable i_entryFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // events
    event EnterLottery(address indexed player);
    event WinnerPicked(address indexed winner);

    //Modifiers
    modifier onlyOpenRaffle() {
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__RaffleNotOpen();
        }
        _;
    }

    constructor(
        uint256 entryFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entryFee = entryFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    /// @notice This allows an address to participate in a lottery
    /// @dev This checks if the address has sent the current value of eth befor partaking in the lottery
    function enterLottery() external payable onlyOpenRaffle {
        if (msg.value < i_entryFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnterLottery(msg.sender);
    }

    function performUpkeep(bytes calldata /*performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }
        s_raffleState = RaffleState.CALCULATING;
        i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);
        (bool s, ) = winner.call{value: address(this).balance}("");
        if (!s) {
            revert Raffle__TransferFailed();
        }
    }

    /// @notice This returns back the i_entryFee value
    /// @return a uint256 value
    function getIentryFee() public view returns (uint256) {
        return i_entryFee;
    }
}
