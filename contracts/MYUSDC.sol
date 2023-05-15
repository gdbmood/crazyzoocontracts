// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MYUSDC is ERC20 {
    constructor() ERC20("MockToken#1", "MYUSDC#1") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

