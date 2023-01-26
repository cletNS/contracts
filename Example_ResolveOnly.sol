// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Clet Name Service
/// @author Clet Inc.
/// @notice This is an example contract that shows how to resolve clet names on the Calypso Hub Mainnet (Skale Chain)
/// @dev All function inputs must be lowercase to prevent undesirable results
/// @custom:contact hello@clet.domains

import "https://github.com/cletNS/interfaces/blob/master/ICletCore.sol";

contract Example_Clet_Usage {
    /// @dev You can remove constant declarations and add a function to make changes after deploy.
    /// Might be helpful for switching between staging and mainnet.
    address private constant CletCoreContract =
        0x261Cf6D8b58a9492B8B9b272cF36EF659E1e65b9;

    /// @notice Resolves a full clet name
    function resolve(
        string memory _name_ticker
    ) public view returns (ICletCore.MappedAddress memory) {
        return ICletCore(CletCoreContract).resolve(_name_ticker);
    }

    /// @notice Returns the name belonging to a mapped information
    function reverseLookup(
        string memory _address
    ) public view returns (string memory) {
        return ICletCore(CletCoreContract).reverseLookup(_address);
    }
}
