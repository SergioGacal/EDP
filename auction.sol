// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Auction Contract
/// @notice This contract allows users to participate in an auction by placing bids.
/// @dev This contract uses several functions and modifiers to manage an auction.
///      The auction starts upon deployment and remains active until the set time limit
///      or until the owner ends it. The auction logic requires a minimum 5% increment
///      over the current highest bid and automatically extends the auction if less than
///      10 minutes remain when a bid is placed. Upon conclusion, the contract refunds
///      deposits minus a 2% commission, transferring the remaining balance to the owner.
contract Auction {
    
    uint256 auctionEnd;
    address owner;
    address currentWinner;
    uint256 currentWinningBid;
    mapping(address => uint256) balances;
    mapping(address => uint256) lastBid;
    mapping(address => uint256[]) bidDetails;
    address[] bidders;
    bool auctionIsActive;

    /// @notice Event emitted upon receiving a new bid in the auction
    /// @param bidder Address of the user who placed the bid
    /// @param bidAmount Bid amount
    event NewBid(address indexed bidder, uint256 bidAmount);

    /// @notice Event emitted when the auction ends
    /// @param auctionWinner Address of the auction's winning bidder
    /// @param winningBidAmount Winning bid amount
    event AuctionEnded(address auctionWinner, uint256 winningBidAmount);

    /// @dev Verifies that the sender is the contract owner (administrator). 
    ///      Although not required, it prevents the owner from placing bids, ensuring fair bidding.
    modifier administrator(){
        require(msg.sender == owner, "Owner or Administrator required");
        _;
    }

    /// @dev Ensures the sender is not the owner, allowing only non-owners to place bids
    modifier bidder(){
        require(msg.sender != owner, "Owner cannot bid");
        _;
    }

    /// @dev Ensures the auction is active before allowing an action
    modifier activeAuction(){
        require(auctionIsActive, "Auction inactive");
        _;
    }

    /// @dev Ensures the auction is inactive before allowing an action
    modifier inactiveAuction(){
        require(!auctionIsActive, "Wait for auction end");
        _;
    }

    /// @notice Constructor to initialize the auction with a specified duration
    /// @param durationInSeconds Auction duration in seconds
    constructor(uint256 durationInSeconds) {
        owner = msg.sender;
        auctionEnd = block.timestamp + durationInSeconds;
        auctionIsActive = true;
    }

    /// @notice Shows information about the current auction state. Used for testing in Remix and viewing the remaining auction time.
    /// @return description Description of the remaining seconds
    /// @return timeRemaining Remaining auction time in seconds
    /// @return ownerLabel Description of the owner
    /// @return theOwner Address of the auction owner
    /// @return winnerLabel Description of the current winner
    /// @return winner Address of the current highest bidder
    /// @return amountLabel Description of the highest bid
    /// @return amount Current highest bid
    function info() external view activeAuction returns ( string memory description, uint256 timeRemaining, string memory ownerLabel, address theOwner, string memory winnerLabel, address winner, string memory amountLabel,uint256 amount) {
        return ("Remaining seconds", auctionEnd - block.timestamp, "Owner", owner, "Current winner", currentWinner, "Bid", currentWinningBid);
    }

    /// @notice Places a bid in the auction
    /// @dev Extends the auction time by 10 minutes if less than 10 minutes remain
    /// @dev Requires the bid to be at least 5% higher than the current winning bid
    /// @dev Updates mappings and variables
    function makeBid() payable external activeAuction bidder{
        uint256 isNow = block.timestamp;
        uint256 currentBid = msg.value;
        address currentBidder = msg.sender;
        bool lessThanTenMinutesLeft = auctionEnd - isNow <= 600;

        require(isNow < auctionEnd, "Auction has ended");
        require(currentBid > currentWinningBid * 105 / 100, "bid increment percentage too low");

        if (lessThanTenMinutesLeft) {
            auctionEnd += 600;
        }

        if (balances[currentBidder] == 0) {
            bidders.push(currentBidder);
        }

        lastBid[currentBidder] = currentBid;
        balances[currentBidder] += currentBid;
        bidDetails[currentBidder].push(currentBid);
        currentWinner = currentBidder;
        currentWinningBid = currentBid;

        emit NewBid(currentBidder, currentBid);
    }

    /// @notice Requests a partial refund, leaving the last bid as collateral
    /// @dev Requires that funds are available for withdrawal over the last winning bid from that address
    function partialRefund() payable external activeAuction bidder{
        address withdrawer = msg.sender;
        uint256 amount = balances[withdrawer] - lastBid[withdrawer];
        require(amount > 0, "No funds available for withdrawal");
        balances[withdrawer] -= amount;
        payable(withdrawer).transfer(amount);
    }

    /// @notice Shows current bidders' addresses and balances
    /// @return bidderAddress List of bidders' addresses
    /// @return bidderBalance List of each bidder's balance
    function viewBalances() external view activeAuction returns (string memory, address[] memory, string memory, uint256[] memory)  {
        uint256 total = bidders.length;
        address[] memory bidderAddress = new address[](total);
        uint256[] memory bidderBalance = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            bidderAddress[i] = bidders[i];
            bidderBalance[i] = balances[bidders[i]];
        }
        return ("Addresses:", bidderAddress, "Balances", bidderBalance);
    }

    /// @notice Ends the auction and returns deposits to all participants minus commission
    function endAuction() external activeAuction administrator {
        require(block.timestamp > auctionEnd, "Wait until bidding time ends");
        auctionIsActive = false;
        refundAllDeposits();
        emit AuctionEnded(currentWinner, currentWinningBid);
    }
    
    /// @notice Displays the winner and winning bid amount after the auction ends
    /// @return winner Address of the auction winner
    /// @return amount Winning bid amount
    function announceWinner() external view inactiveAuction returns (address winner, uint256 amount)  {
        return (currentWinner, currentWinningBid);
    }

    /// @notice Refunds all deposits to bidders at auction end
    /// @dev Requires the auction to be inactive
    function refundAllDeposits() internal inactiveAuction {
        uint256 totalRefunds = bidders.length;
        for (uint256 i = 0; i < totalRefunds; i++) {
            address refundReceiver = bidders[i];
            uint256 refundAmount = balances[refundReceiver];
            if (refundAmount > 0) {
                balances[refundReceiver] = 0;
                payable(refundReceiver).transfer(refundAmount * 98 / 100); 
            }
        }
        payable(owner).transfer(address(this).balance);
    }
}
