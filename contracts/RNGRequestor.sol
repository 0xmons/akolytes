// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

contract RNGRequestor is VRFConsumerBase {

  uint256 internal immutable fee;
  bytes32 internal immutable keyHash;
  LinkTokenInterface private immutable link;

  // This is what gets set on callback
  mapping(bytes32 => uint256) public rng;

  constructor(uint256 _fee, address vrfCoordinatorAddress, address linkAddress, bytes32 _keyHash) 
    VRFConsumerBase(vrfCoordinatorAddress, linkAddress) {
      fee = _fee;
      keyHash = _keyHash;
      link = LinkTokenInterface(linkAddress);
  }

  function requestRNG() public returns (bytes32) {
    return requestRNG(fee);
  }

  function requestRNG(uint256 explicitFee) public returns (bytes32 requestId) {
    // If we don't have enough tokens for the fee, try to transfer the funds,
    // then make the rng request and return the request ID
    // (we assume we have approval)
    uint256 contractBalance = link.balanceOf(address(this));
    if (contractBalance < explicitFee) {
      link.transferFrom(msg.sender, address(this), explicitFee);
    }
    requestId = requestRandomness(keyHash, explicitFee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    rng[requestId] = randomness;
  }
}