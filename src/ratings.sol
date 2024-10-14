// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.23;

contract Rating {
    struct ratingData {
        // First slot
        /* For debugging 
        uint40 zero;
        uint40 one;
        uint40 two;
        uint40 three;
        uint40 four;
        uint40 five;
        uint16 padding; */
        uint256 ratingSlot;
        // Second slot
        uint256 total;
        // Third slot
        mapping(address => uint40) timeout;
    }

    uint48 constant MAXCOUNT = 2 ** 42 - 1;
    uint16 public constant MULTIPLIER = 1000;

    mapping(address => ratingData) private s_data;
    uint96 private s_totalRatings;
    string[] private s_comment;

    function rateAddress(address _address, uint8 rating) external payable {
        require(rating < 6);
        uint256 slot;
        uint256 value;
        uint256 rToWrite;
        uint256 timeOut;
        assembly {
            slot := s_data.slot
        }
        // Directly hash the address key
        bytes32 location0 = keccak256(abi.encode(_address, slot));
        bytes32 location1 = bytes32(uint256(location0) + 1);
        // Load the second slot
        assembly {
            value := sload(location1)
        }
        uint256 mask = 0x0000000000000000000000000000000000000000000000000000FFFFFFFFFFFF;
        uint48 total = uint48(mask & value);
        require(total < MAXCOUNT);
        // Check for timeout
        bytes32 location2 = keccak256(
            abi.encode(msg.sender, bytes32(uint256(location1) + 1))
        );
        assembly {
            timeOut := sload(location2)
        }
        uint256 bTimeStamp = block.timestamp;
        require(
            timeOut < bTimeStamp,
            "Address rating only one time per 24 hours"
        );
        timeOut = bTimeStamp + 86400;
        assembly {
            sstore(location2, timeOut)
        }
        // Add the new rating
        assembly {
            value := add(value, 1)
            sstore(location1, value)
        }
        rToWrite = 2 ** (40 * rating);
        assembly {
            value := sload(location0)
            value := add(value, rToWrite)
            sstore(location0, value)
        }
        s_totalRatings += 1;
    }

    function getRating(
        address _address
    ) external view returns (uint48, uint48) {
        uint256 slot;
        assembly {
            slot := s_data.slot
        }
        // Directly hash the address key
        bytes32 location = keccak256(abi.encode(_address, slot));
        uint256 slotData;
        assembly {
            slotData := sload(location)
        }
        uint48 sum = getOne(slotData) +
            2 *
            getTwo(slotData) +
            3 *
            getThree(slotData) +
            4 *
            getFour(slotData) +
            5 *
            getFive(slotData);
        location = bytes32(uint256(location) + 1);
        assembly {
            slotData := sload(location)
        }
        uint256 mask = 0x0000000000000000000000000000000000000000000000000000FFFFFFFFFFFF;
        uint48 total = uint48(mask & slotData);
        if (total != 0) return ((sum * MULTIPLIER) / total, total);
        else return (0, 0);
    }

    function getFive(uint256 slotData) internal pure returns (uint40) {
        uint256 mask = 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 bits = slotData & mask;
        return uint40(bits >> 200); // Shift right to bring the high bits to the least significant positions
    }

    function getFour(uint256 slotData) internal pure returns (uint40) {
        uint256 mask = 0x00000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 bits = slotData & mask;
        return uint40(bits >> 160); // Shift right to bring the high bits to the least significant positions
    }

    function getThree(uint256 slotData) internal pure returns (uint40) {
        uint256 mask = 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 bits = slotData & mask;
        return uint40(bits >> 120); // Shift right to bring the high bits to the least significant positions
    }

    function getTwo(uint256 slotData) internal pure returns (uint40) {
        uint256 mask = 0x0000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 bits = slotData & mask;
        return uint40(bits >> 80); // Shift right to bring the high bits to the least significant positions
    }

    function getOne(uint256 slotData) internal pure returns (uint40) {
        uint256 mask = 0x00000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFF;
        uint256 bits = slotData & mask;
        return uint40(bits >> 40); // Shift right to bring the high bits to the least significant positions
    }

    function getZero(uint256 slotData) internal pure returns (uint40) {
        uint256 mask = 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF;
        uint256 bits = slotData & mask;
        return uint40(bits);
    }

    function getNumberOfRatings() external view returns (uint96) {
        return s_totalRatings;
    }

    function getTimeOut(address _address) external view returns (uint256) {
        uint256 slot;
        uint256 timeOut;
        assembly {
            slot := s_data.slot
        }
        bytes32 location2 = keccak256(
            abi.encode(
                msg.sender,
                bytes32(uint256(keccak256(abi.encode(_address, slot))) + 2)
            )
        );
        assembly {
            timeOut := sload(location2)
        }
        return timeOut;
    }

    /* FOR DEBUG
    function getRate(address _address) external view returns (uint48, uint256, uint40) {
        return (s_data[_address].one + 2 * s_data[_address].two + 3 * s_data[_address].three + 4 * s_data[_address].four + 5 * s_data[_address].five,
            s_data[_address].total,
            s_data[_address].timeout[msg.sender]);
    }
*/
    function addComment(string memory _comment) external {
        s_comment.push(_comment);
    }

    function getNumberOfComments() external view returns (uint256) {
        return s_comment.length;
    }

    function getComments() external view returns(string[] memory) {
        return s_comment;
    }
}
