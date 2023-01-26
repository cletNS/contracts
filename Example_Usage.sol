// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Clet Name Service
/// @author Clet Inc.
/// @notice This is an example contract that shows how to resolve clet names on the Calypso Hub Mainnet (Skale Chain)
/// @dev All function inputs must be lowercase to prevent undesirable results
/// @custom:contact hello@clet.domains

import "https://github.com/cletNS/interfaces/blob/master/ICletCore.sol";
import "https://github.com/cletNS/interfaces/blob/master/ICustomResolver.sol";
import "https://github.com/cletNS/interfaces/blob/master/ICustomNameService.sol";

contract Example_Clet_Usage {
    /// @dev You can remove constant declarations and add a function to make changes after deploy.
    /// Might be helpful for switching between staging and mainnet.
    address private constant CletCoreContract =
        0x261Cf6D8b58a9492B8B9b272cF36EF659E1e65b9;

    /// @dev Optional: Only use this with 'resolveCustom' & 'reverseCustom' functions
    address private constant CletCustomNameService =
        0x935fcCdD4c0b6984CFB95b5d635DFcf31aB1c04B;

    /// @notice Resolves a full clet name
    function resolve(
        string memory _name_ticker
    ) public view returns (ICletCore.MappedAddress memory) {
        return ICletCore(CletCoreContract).resolve(_name_ticker);
    }

    /// @notice Returns the the owner of a clet name
    function getOwner(string memory _name) public view returns (address) {
        return ICletCore(CletCoreContract).getOwner(_name);
    }

    /// @notice Returns all mappedInfo of a name
    function getAllMappedInfo(
        string memory _name
    ) public view returns (string[] memory) {
        return ICletCore(CletCoreContract).getAllMappedInfo(_name);
    }

    /// @notice Returns the name belonging to a mapped information
    function reverseLookup(
        string memory _address
    ) public view returns (string memory) {
        return ICletCore(CletCoreContract).reverseLookup(_address);
    }

    /// @notice Returns an array of valid tickers
    function getTickers() public view returns (ICletCore.Ticker[] memory) {
        return ICletCore(CletCoreContract).getTickers();
    }

    /// @dev Does not require ticker
    /// @notice Resolves a sub/customised clet name
    function resolveCustom(
        string memory _name,
        uint256 _resolverIndex
    ) public view returns (ICustomResolver.MappedAddress memory) {
        return
            ICustomNameService(CletCustomNameService).resolve(
                _name,
                _resolverIndex
            );
    }

    /// @notice Returns a sub/customised clet name
    function reverseCustom(
        string memory _address,
        uint256 _resolverIndex
    ) public view returns (string memory) {
        return
            ICustomNameService(CletCustomNameService).reverseLookup(
                _address,
                _resolverIndex
            );
    }
}
