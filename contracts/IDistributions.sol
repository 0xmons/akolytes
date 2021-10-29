// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

interface IDistribution {
  function d1(uint256 start, uint256 end, uint256 rng) external returns (uint256);
  function d2(uint256 start, uint256 end, uint256 seed) external returns (uint256);
  function d3(uint256 start, uint256 end, uint256 seed) external returns (uint256);
  function d4(uint256 start, uint256 end, uint256 seed) external returns (uint256);
}