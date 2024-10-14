// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.23;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

contract Giveout {
    IERC20 private immutable i_token;
    uint constant AMOUNT = 100 ether;
    mapping(address => bool) private s_distributed;

    constructor(address _tokenContract) {
        i_token = IERC20(_tokenContract);
    }

    function get() external {
        require(
            !s_distributed[msg.sender],
            "Giveout is distributed only once per address"
        );
        require(i_token.balanceOf(address(this)) > AMOUNT);
        s_distributed[msg.sender] = true;
        i_token.transfer(msg.sender, AMOUNT);
    }

    function getBalance() external view returns (uint) {
        return (i_token.balanceOf(address(this)));
    }
}
