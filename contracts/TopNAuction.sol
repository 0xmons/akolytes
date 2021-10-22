// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

contract TopNAuction {

  struct Bid {
    address from;
    uint96 amount;
  }

  uint256 constant private N_WINNERS = 150;
  uint256 public numBids;
  mapping(uint256 => Bid) bidList;
  bytes32 bidListChecksum;

  function addBid(Bid[] calldata currentBidList, uint256 minIndex, bytes32 newChecksum) external payable {
    require(msg.value < 79228162514264337593543950336, "Greater than 96 bits");
    // If we aren't full yet, just add it to the list
    if (numBids < N_WINNERS) {
      bidList[numBids] = Bid(
        msg.sender,
        uint96(msg.value)
      );
      numBids += 1;
    }
    // Otherwise, we will need to:
    // - validate the supplied list is correct
    // - validate the supplied index is the minimum
    // - validate the supplied checksum matches the new list
    // - update the actual list
    // - update the actual checksum
    else {
      
      // Calculate the checksum of the list of bids passed in
      // Checksum is the keccak256 of the XOR of all the values 
      Bid memory firstBid = currentBidList[0];
      uint256 currentBidsAccumulator = uint256(uint160(firstBid.from)) ^ firstBid.amount;
      for (uint256 i = 1; i < numBids; i++) {
        currentBidsAccumulator = currentBidsAccumulator ^ uint256(uint160(currentBidList[i].from)) ^ currentBidList[i].amount;
      }
      require(bidListChecksum == keccak256(abi.encodePacked(currentBidsAccumulator)), "Checksum doesn't match");

      // Verify that the selected index is actually the least
      uint256 minAmount = currentBidList[minIndex].amount;
      for (uint256 i = 0; i < numBids; i++) {
        require(currentBidList[i].amount >= minAmount, "Index provided is not min value");
      }

      // Calculate the new checksum
      // Undo the XOR provided by the minBid value and XOR the new value
      // Check against provided value
      uint256 newBidsAccumulator = currentBidsAccumulator ^ uint256(uint160(currentBidList[minIndex].from)) ^ currentBidList[minIndex].amount;
      newBidsAccumulator = newBidsAccumulator ^ uint256(uint160(address(msg.sender))) ^ msg.value;
      require(newChecksum == keccak256(abi.encodePacked(newBidsAccumulator)), "New checksum incorrect");

      // Actually write new values to storage
      bidList[minIndex] = Bid(
        msg.sender,
        uint96(msg.value)
      );
      bidListChecksum = newChecksum;
    } 
  }
}