// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

library UtilityLibrary{

    function extractOrgId(string memory _userElectionID) internal pure returns (string memory) {
        string[] memory parts = UtilityLibrary.splitString(_userElectionID, "-");
        require(parts.length > 0, "Invalid custom election ID format");

        return parts[0];
    }

    function decodeBytes10(bytes10 data) internal pure returns (string memory) {
        string memory decodedString = new string(10);
        
        assembly {
            mstore(add(decodedString, 32), data)
        }

        return decodedString;
    }
    
    function arrayContains(string[] storage array, string memory element) internal view returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (keccak256(abi.encodePacked(array[i])) == keccak256(abi.encodePacked(element))) {
                return true;
            }
        }
        return false;
    }
    
    function onlyAlphanumericCharacters(string memory _input) internal pure returns (bool) {
        bytes memory b = bytes(_input);
        for (uint i = 0; i < b.length; i++) {
            if (!((uint8(b[i]) >= 48 && uint8(b[i]) <= 57) || // 0-9
                (uint8(b[i]) >= 65 && uint8(b[i]) <= 90) || // A-Z
                (uint8(b[i]) >= 97 && uint8(b[i]) <= 122))) { // a-z
                return false;
            }
        }
        return true;
    }

    function appendToStringArray(string[] memory array, string memory newValue) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](array.length + 1);
        
        for (uint32 i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        
        newArray[array.length] = newValue;
        
        return newArray;
    }

    function containsWhitespaceCheck(string memory _str) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);

        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == " ") {
                return true; 
            }
        }

        return false; 
    }


    function uintToString(uint48 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint48 temp = value;
        uint48 length;
        while (temp != 0) {
            length++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(length);
        uint48 i = length - 1;
        while (value != 0) {
            buffer[i] = bytes1(uint8(48 + value % 10));
            value /= 10;
            i--;
        }

        return string(buffer);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function splitString(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);

        uint delimiterCount = 1;
        for (uint i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiterBytes[0]) {
                delimiterCount++;
            }
        }

        string[] memory parts = new string[](delimiterCount);

        uint partStart = 0;
        uint partIndex = 0;
        for (uint i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiterBytes[0]) {
                parts[partIndex] = substring(str, partStart, i);
                partStart = i + 1;
                partIndex++;
            }
        }

        // Add the last part
        parts[partIndex] = substring(str, partStart, strBytes.length);

        return parts;
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex <= endIndex && endIndex <= strBytes.length, "Invalid substring indices");

        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }

        return string(result);
    }

    function extractOrgIdFromElectionId(string memory _userElectionID) internal pure returns (string memory) {
        bytes memory orgIdBytes = bytes(_userElectionID);

        // Split the input string at the hyphen ('-')
        uint8 i = 0;
        while (i < orgIdBytes.length && orgIdBytes[i] != '-'){  // ASCII code for hyphen '-'
            i++;
        }

        // If a hyphen is found, extract the organization ID
        if (i < orgIdBytes.length) {
            bytes memory extractedBytes = new bytes(i);
            for (uint8 j = 0; j < i; j++) {
                extractedBytes[j] = orgIdBytes[j];
            }
            return string(extractedBytes);
        }

        return "";
    }

    function concat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }


}