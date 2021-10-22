// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Trust.sol";
import "./IRNGRequestor.sol";
import "./ITokenURI.sol";

contract Akolytes is Trust, ERC721Enumerable {

  uint256 constant private MAX_SUPPLY = 512;

  IRNGRequestor immutable private rngRequestor;
  ITokenURI immutable private tokenURICreator;
  IERC721Enumerable immutable private mons;

  bytes32 public requestId;
  bool public alreadyRequestedRNG;

  constructor(
    address rngAddress,
    address tokenURIAddress,
    address monAddress
  ) ERC721("Akolytes", "AKOLYTES") Trust(msg.sender) {
    rngRequestor = IRNGRequestor(rngAddress);
    tokenURICreator = ITokenURI(tokenURIAddress);
    mons = IERC721Enumerable(monAddress);
  }

  function requestRNG() external requiresTrust {
    require(! alreadyRequestedRNG, "Already requested");
    require(totalSupply() == MAX_SUPPLY, "Not all out");
    requestId = rngRequestor.requestRNG();
    alreadyRequestedRNG = true;
  }

  // Used for dutch auction and admin minting
  function mint(address to, uint256 id) external requiresTrust {
    require(totalSupply() < MAX_SUPPLY, "MAX_SUPPLY");
    _mint(to, id);
  }

  function tokenURI(uint256 id) public view override returns(string memory) {
    return tokenURICreator.tokenURI(id, rngRequestor.rng(requestId));
  }

  // For 0xmons holders to claim
  // No need to keep track of claimed IDs b/c mint will fail if ID already exists
  function claimForMons(uint256[] calldata ids) external {
    for (uint256 i = 0; i < ids.length; i++) {
      require(mons.ownerOf(ids[i]) == msg.sender, "Not owner");
      _mint(msg.sender, ids[i]);
    }
  }
}