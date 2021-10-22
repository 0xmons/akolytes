// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Trust.sol";
import "./IMinter.sol";

contract DutchAuction is Trust, ReentrancyGuard {

  // The Auction will mint NFTs sequentually from START_INDEX to END_INDEX (inclusive)
  // The price will start at START_PRICE and drop to 0 over the course of AUCTION_DURATION
  uint256 constant START_INDEX = 342;
  uint256 constant END_INDEX = 500;
  uint256 constant START_PRICE = 100 ether;
  uint256 constant AUCTION_DURATION = 1 days;
  address constant XMON_MULTISIG = 0x4e2f98c96e2d595a83AFa35888C4af58Ac343E44;

  IMinter immutable akolytes; 

  uint256 startTime;
  bool hasStarted;
  uint256 currentIndex = START_INDEX;

  constructor(address akolytesAddress) Trust(msg.sender) {
    akolytes = IMinter(akolytesAddress);
  }

  function startAuction() public requiresTrust {
    require(!hasStarted, "Already started");
    startTime = block.timestamp;
    hasStarted = true;
  }

  function getPrice() public view returns (uint256 currentPrice) {
    uint256 elapsedTime = block.timestamp - startTime;
    uint256 priceDropSoFar = START_PRICE*elapsedTime/AUCTION_DURATION;
    if (priceDropSoFar > START_PRICE) {
      currentPrice = 0;
    }
    else {
      currentPrice = START_PRICE-priceDropSoFar;
    }
  }

  function bid(uint256 numNFTs) public payable nonReentrant returns (uint256 excessAmount) {
    require(hasStarted, "Wait for start");
    require(msg.value >= getPrice()*numNFTs, "too little");
    require(currentIndex + numNFTs <= END_INDEX + 1, "All out");
    uint256 mintIndex = currentIndex;

    // Mint all NFTs to buyer
    for (uint256 i = 0; i < numNFTs; i++) {
      akolytes.mint(msg.sender, mintIndex);
      mintIndex += 1;
    }
    // Set new mint index
    currentIndex = mintIndex;

    // Send the excess eth back to the caller
    if (msg.value > getPrice()) {
      excessAmount = msg.value - getPrice();
      msg.sender.call{value: excessAmount}("");
    }
    else {
      excessAmount = 0;
    }
  }

  // Half to multisig, half to deployer
  function claimETH() public requiresTrust {
    uint256 balance = address(this).balance;
    XMON_MULTISIG.call{value: balance/2}("");
    msg.sender.call{value: balance/2}("");
  } 
}