// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

interface IRNGRequestor {
  function requestRNG() external returns(bytes32);
  function requestRNG(uint256 fee) external returns(bytes32);
  function rng(bytes32 requestId) external view returns(uint256);
}