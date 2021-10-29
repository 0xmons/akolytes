// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

contract Distributions {

  // Start and end are inclusive for all of these

  // Uniform distribution
  function d1(uint256 start, uint256 end, uint256 seed) public pure returns (uint256 result) {
    uint256 diff = end + 1 - start;
    result = (seed % diff) + start;
  }

  // Modal distribution, centered on (start+end)/2
  function d2(uint256 start, uint256 end, uint256 seed) public pure returns (uint256 result) {
    uint256 subresult1 = d1(start, end, seed);
    uint256 seed2 = uint256(keccak256(abi.encode(seed, start, end)));
    uint256 subresult2 = d1(start, end, seed2);
    result = (subresult1 + subresult2)/2;
  }

  // Symmetric distribution, with max density on start and end and least density on (start+end)/2
  function d3(uint256 start, uint256 end, uint256 seed) public pure returns (uint256 result) {
    uint256 midpoint = (start+end)/2;
    uint256 d2Value = d2(start, end, seed);
    if (d2Value >= midpoint) {
      result = end - (d2Value-midpoint);
    }
    else {
      result = start + (midpoint-d2Value);
    }
  }

  // Even-favored distribution
  // If odd, re-rolls
  function d4(uint256 start, uint256 end, uint256 seed) public pure returns (uint256 result) {
    result = d1(start, end, seed);
    if (result % 2 == 1) {
      result = d1(start, end, uint256(keccak256(abi.encode(seed, start, end))));
    } 
  }

  // Start-unfavored distribution
}