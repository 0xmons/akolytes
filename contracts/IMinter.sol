// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

interface IMinter {
  function mint(address to, uint256 id) external;
}