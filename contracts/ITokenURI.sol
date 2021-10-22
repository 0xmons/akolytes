// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

interface ITokenURI {
  function tokenURI(uint256 id, uint256 rng) external view returns(string memory);
}