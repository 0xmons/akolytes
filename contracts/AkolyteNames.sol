library strings {
  struct slice {
      uint _len;
      uint _ptr;
  }
  
  function memcpy(uint dest, uint src, uint len) private pure {
      // Copy word-length chunks while possible
      for(; len >= 32; len -= 32) {
          assembly {
              mstore(dest, mload(src))
          }
          dest += 32;
          src += 32;
      }

      // Copy remaining bytes
      uint mask = 256 ** (32 - len) - 1;
      assembly {
          let srcpart := and(mload(src), not(mask))
          let destpart := and(mload(dest), mask)
          mstore(dest, or(destpart, srcpart))
      }
  }

  /*
    * @dev Returns a slice containing the entire string.
    * @param self The string to make a slice from.
    * @return A newly allocated slice containing the entire string.
    */
  function toSlice(string memory self) internal pure returns (slice memory) {
      uint ptr;
      assembly {
          ptr := add(self, 0x20)
      }
      return slice(bytes(self).length, ptr);
  }

  /*
    * @dev Copies a slice to a new string.
    * @param self The slice to copy.
    * @return A newly allocated string containing the slice's text.
    */
  function toString(slice memory self) internal pure returns (string memory) {
      string memory ret = new string(self._len);
      uint retptr;
      assembly { retptr := add(ret, 32) }

      memcpy(retptr, self._ptr, self._len);
      return ret;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
      uint ptr = selfptr;
      uint idx;

      if (needlelen <= selflen) {
          if (needlelen <= 32) {
              bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

              bytes32 needledata;
              assembly { needledata := and(mload(needleptr), mask) }

              uint end = selfptr + selflen - needlelen;
              bytes32 ptrdata;
              assembly { ptrdata := and(mload(ptr), mask) }

              while (ptrdata != needledata) {
                  if (ptr >= end)
                      return selfptr + selflen;
                  ptr++;
                  assembly { ptrdata := and(mload(ptr), mask) }
              }
              return ptr;
          } else {
              // For long needles, use hashing
              bytes32 hash;
              assembly { hash := keccak256(needleptr, needlelen) }

              for (idx = 0; idx <= selflen - needlelen; idx++) {
                  bytes32 testHash;
                  assembly { testHash := keccak256(ptr, needlelen) }
                  if (hash == testHash)
                      return ptr;
                  ptr += 1;
              }
          }
      }
      return selfptr + selflen;
  }

  /*
    * @dev Splits the slice, setting `self` to everything after the first
    *      occurrence of `needle`, and `token` to everything before it. If
    *      `needle` does not occur in `self`, `self` is set to the empty slice,
    *      and `token` is set to the entirety of `self`.
    * @param self The slice to split.
    * @param needle The text to search for in `self`.
    * @param token An output parameter to which the first token is written.
    * @return `token`.
    */
  function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
      uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
      token._ptr = self._ptr;
      token._len = ptr - self._ptr;
      if (ptr == self._ptr + self._len) {
          // Not found
          self._len = 0;
      } else {
          self._len -= token._len + needle._len;
          self._ptr = ptr + needle._len;
      }
      return token;
  }

  /*
    * @dev Splits the slice, setting `self` to everything after the first
    *      occurrence of `needle`, and returning everything before it. If
    *      `needle` does not occur in `self`, `self` is set to the empty slice,
    *      and the entirety of `self` is returned.
    * @param self The slice to split.
    * @param needle The text to search for in `self`.
    * @return The part of `self` up to the first occurrence of `delim`.
    */
  function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
      split(self, needle, token);
  }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

contract AkolyteNames {

  using strings for string;
  using strings for strings.slice;

  // Name generation process: 1 random from s1, 1 random from s2, and then 0-2 from s3
  string private constant s1 = "Cth,Az,Ap,Ch,Bl,Gh,Gl,Kr,M,Nl,Ny,D,Xy,Rh,U,Bl,Cz,En,Fz,H,Il,J,Jh,Y,YvK,Z,Zh,Sl,T,O,U,Ub,Os,Eh,Sh";
  uint256 private constant s1Length = 35;
  
  string private constant s2 = "ak,al,es,et,id,il,id,oo,or,ux,un,ap,ek,ex,in,ol,up,-af,-aw,'et,'ed,-in,-is,'od,-at,-of";
  uint256 private constant s2Length = 26;

  string private constant s3 = "ag,al,on,ak,ash,a,ber,bal,buk,cla,ced,ck,dar,dru,est,end,fli,fa,-fur,gen,ga,his,ha,ilk,in,-in,ju,ja,-ki,ll,lo,mo,-mu,ma,no,r,ss,sh,sto,ta,tha,un,vy,va,wy,wu,y,yy,z,zs,ton,gon,-man,lu,get,har,uz,ek,ec,-s";
  uint256 private constant s3Length = 60;

  // Max number of times we grab a syllable from s3
  uint256 private constant maxS3Iters = 2;

  function getName(uint256 seed) external pure returns (string memory) {
    uint256 rng = seed;
    // Get uniform from s1
    string memory nameS1 = getItemFromCSV(s1, rng % s1Length);
    // Update seed
    rng = uint256(keccak256(abi.encode(rng)));
    // Get uniform from s2
    string memory nameS2 = getItemFromCSV(s2, rng % s2Length);
    // Concatenate the two 
    string memory name = string(abi.encodePacked(nameS1, nameS2));
    // Update seed
    rng = uint256(keccak256(abi.encode(rng)));
    // Add any s3 syllables (if possible)
    for (uint256 i = 0; i < rng % (maxS3Iters + 1); i++) {
      string memory nameS3 = getItemFromCSV(s3, rng % s3Length);
      rng = uint256(keccak256(abi.encode(rng)));
      name = string(abi.encodePacked(name, nameS3));
    }
    return name;
  }

  function getItemFromCSV(string memory str, uint256 index) internal pure returns (string memory) {
    strings.slice memory strSlice = str.toSlice();
    string memory separatorStr = ",";
    strings.slice memory separator = separatorStr.toSlice();
    strings.slice memory item;
    for (uint256 i = 0; i <= index; i++) {
        item = strSlice.split(separator);
    }
    return item.toString();
  }
}