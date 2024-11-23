// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @title TokenA - ERC20 token for a decentralized exchange (DEX) example
/// @notice This contract deploys an ERC20 token named TokenA (TKA)
/// @dev This contract inherits the ERC20 implementation from OpenZeppelin
contract TokenA is ERC20 {
    /// @notice Constructor that initializes the token with an initial supply
    /// @dev The `_mint` function mints `1000000 * 10**decimals()` tokens to the deployer's address
    constructor() ERC20("TokenA", "TKA") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}
