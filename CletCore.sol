// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Clet Name Service
/// @author Clet Inc.
/// @notice You can use this contract for managing clet names
/// @dev All function inputs must be lowercase to prevent undesirable results
/// @custom:contact hello@clet.domains

import "./StringManipulation.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error CletNameService__NameUnavailable();
error CletNameService__Unauthorized();
error CletNameService__AlreadyMapped();
error CletNameService__InsufficientFunds();
error CletNameService__NotForSale();
error CletNameService__Empty();

contract CLETCORE is Ownable {
    using StringManipulation for *;

    CletName[] public s_CletNames;
    Ticker[] public s_Tickers;
    uint256 private constant TenPow18 = 10 ** 18;
    address private emptyAddress;
    address private constant VALIDATOR =
        0xf0802222a2908DF9B30b34076c95E39F375F46D9;
    mapping(string => bool) private name_Exists;
    mapping(string => MappedAddress) private name_ext_ToMap;
    mapping(string => address) private name_ToOwner;
    mapping(string => string) private name_Secret;
    mapping(address => string) private address_Default;
    mapping(address => mapping(string => string)) public address_key_name;
    mapping(address => string[]) public address_OwnedNames;
    mapping(address => string[]) private address_Keys;
    mapping(string => uint256) private name_ToID;
    mapping(string => string) private mapTo_name_ex;

    struct Ticker {
        string name;
        string ticker;
        string icon;
        string tag;
    }

    struct MappedAddress {
        Ticker ticker;
        string mappedAddress;
    }

    struct CletName {
        address owner;
        string name;
    }

    struct Expiry {
        uint256 startDate;
        uint256 endDate;
    }

    event NameTransfer(
        string _name,
        address indexed _from,
        address indexed _to
    );

    /// @notice Returns the mapped details of a name.ticker
    /// @dev Returns type of MappedAddress
    function resolve(
        string memory _name_ticker
    ) public view returns (MappedAddress memory) {
        return name_ext_ToMap[_name_ticker];
    }

    /// @notice Maps a new address to specified chain
    /// @dev Use getTickers() to ensure index correctness
    function map(
        string memory _address,
        string memory _name,
        uint256 _tickerIndex
    ) public isNameOwner(name_ToOwner[_name.toLower()]) {
        _name = _name.toLower();
        Ticker memory ticker = s_Tickers[_tickerIndex];
        string memory name_ex = string.concat(
            _name,
            ".",
            s_Tickers[_tickerIndex].ticker
        );
        string memory currentMap = name_ext_ToMap[name_ex].mappedAddress;
        if (currentMap.isEqual(_address)) {
            revert CletNameService__AlreadyMapped();
        } else {
            MappedAddress memory ma = MappedAddress(ticker, _address);
            name_ext_ToMap[name_ex] = ma;
            mapTo_name_ex[_address] = name_ex;
        }
    }

    /// @notice Transfers an existing owned name to another account
    function transferName(
        string memory _name,
        address _newOwner
    ) public isNameOwner(name_ToOwner[_name.toLower()]) {
        CletName storage cletname = s_CletNames[name_ToID[_name]];
        deleteMapped(_name, cletname.owner);
        cletname.owner = _newOwner;
        address_OwnedNames[_newOwner].push(_name);
        address _recentOwner = name_ToOwner[_name];
        name_ToOwner[_name] = _newOwner;
        emit NameTransfer(_name, _recentOwner, _newOwner);
    }

    /// @notice Returns the the owner of a clet name
    function getOwner(string memory _name) public view returns (address) {
        return name_ToOwner[_name];
    }

    /// @notice Returns the total number of names in the contract
    function getCount() public view returns (uint256) {
        return s_CletNames.length;
    }

    /// @notice Returns an array of valid tickers
    function getTickers() public view returns (Ticker[] memory) {
        return s_Tickers;
    }

    /// @notice Returns all exisiting names in the contract
    function getAllNames() public view returns (CletName[] memory) {
        return s_CletNames;
    }

    /// @notice Returns names belonging to an account
    function getOwnedNames(
        address _owner
    ) public view returns (string[] memory) {
        uint256 resCount = 0;
        for (
            uint256 index = 0;
            index < address_OwnedNames[_owner].length;
            index++
        ) {
            if (!address_OwnedNames[_owner][index].isEqual("")) {
                resCount++;
            }
        }
        string[] memory data = new string[](resCount);
        uint256 dataIndex = 0;
        for (
            uint256 index = 0;
            index < address_OwnedNames[_owner].length;
            index++
        ) {
            if (!address_OwnedNames[_owner][index].isEqual("")) {
                data[dataIndex] = address_OwnedNames[_owner][index];
                dataIndex++;
            }
        }
        return data;
    }

    function getOwnedNamesLength(address _owner) public view returns (uint256) {
        return address_OwnedNames[_owner].length;
    }

    /// @notice Returns all mappedInfo of a name
    function getAllMappedInfo(
        string memory _name
    ) public view returns (string[] memory) {
        string[] memory data = new string[](s_Tickers.length);
        for (uint256 index = 0; index < s_Tickers.length; index++) {
            string memory name_ex = string.concat(
                _name,
                ".",
                s_Tickers[index].ticker
            );
            data[index] = name_ext_ToMap[name_ex].mappedAddress;
        }
        return data;
    }

    /// @notice Returns the name belonging to a mapped information
    function reverseLookup(
        string memory _address
    ) public view notEmpty(_address) returns (string memory) {
        return mapTo_name_ex[_address];
    }

    /// @notice Sets the default name of an account
    function setDefault(
        string memory _name
    ) public isNameOwner(name_ToOwner[_name.toLower()]) {
        address_Default[msg.sender] = _name;
    }

    /// @notice Adds a key to a name
    function setKey(
        string memory _name,
        string memory _key
    ) public isNameOwner(name_ToOwner[_name.toLower()]) {
        address_key_name[msg.sender][_key] = _name;
        address_Keys[msg.sender].push(_key);
    }

    /// @notice Removes a key from a name
    function removeKey(
        string memory _name,
        string memory _key
    ) public isNameOwner(name_ToOwner[_name.toLower()]) {
        address_key_name[msg.sender][_key] = "0";
    }

    /// @notice Adds a secret to a name
    function setSecret(
        string memory _hash,
        string memory _name
    ) public isNameOwner(name_ToOwner[_name.toLower()]) {
        name_Secret[_name] = _hash;
    }

    /// @notice Validates a secret
    function secretIsValid(
        string memory _name,
        string memory _secret
    ) public view isNameOwner(name_ToOwner[_name.toLower()]) returns (bool) {
        bool valid = false;
        string memory _sHash = keccak256((abi.encodePacked(_secret))).toHex();
        if (name_Secret[_name].isEqual(_sHash)) {
            valid = true;
        }
        return valid;
    }

    function release(address _address, string memory _name) public onlyOwner {
        doRelease(_address, _name);
    }

    function validatorRelease(
        address _address,
        string memory _name
    ) public isValidator {
        doRelease(_address, _name);
    }

    function doRelease(
        address _address,
        string memory _name
    ) private noNull(_name) {
        if (name_Exists[_name] == true) {
            releaseListed(_name, _address);
        } else {
            s_CletNames.push(CletName(_address, _name));
            address_OwnedNames[_address].push(_name);
            name_Exists[_name] = true;
            name_ToOwner[_name] = _address;
            name_ToID[_name] = s_CletNames.length - 1;
        }
    }

    function releaseListed(
        string memory _name,
        address _address
    ) public onlyOwner {
        doReleaseListed(_name, _address);
    }

    function validatorReleaseListed(
        string memory _name,
        address _address
    ) public isValidator {
        doReleaseListed(_name, _address);
    }

    function doReleaseListed(
        string memory _name,
        address _address
    ) private noNull(_name) {
        CletName storage cletname = s_CletNames[name_ToID[_name]];
        deleteMapped(_name, cletname.owner);
        cletname.owner = _address;
        address_OwnedNames[_address].push(_name);
        name_ToOwner[_name] = _address;
    }

    function deleteMapped(string memory _name, address _owner) private {
        for (
            uint256 index = 0;
            index < address_OwnedNames[_owner].length;
            index++
        ) {
            if (address_OwnedNames[_owner][index].isEqual(_name)) {
                delete address_OwnedNames[_owner][index];
            }
        }

        for (uint256 index = 0; index < s_Tickers.length; index++) {
            string memory name_ex = string.concat(
                _name,
                ".",
                s_Tickers[index].ticker
            );
            string memory _address = name_ext_ToMap[name_ex].mappedAddress;
            delete mapTo_name_ex[_address];
            delete name_ext_ToMap[name_ex];
        }

        for (uint256 index = 0; index < address_Keys[_owner].length; index++) {
            delete address_key_name[_owner][address_Keys[_owner][index]];
            delete address_Keys[_owner][index];
        }
        delete address_Default[_owner];
        delete name_Secret[_name];
    }

    function addTicker(
        string memory _name,
        string memory _ticker,
        string memory _icon,
        string memory _tag
    ) public onlyOwner {
        s_Tickers.push(Ticker(_name, _ticker, _icon, _tag));
    }

    function updateTicker(
        uint256 _tickerID,
        string memory _name,
        string memory _ticker,
        string memory _icon,
        string memory _tag
    ) public onlyOwner {
        Ticker storage ticker = s_Tickers[_tickerID];
        ticker.name = _name;
        ticker.ticker = _ticker;
        ticker.icon = _icon;
        ticker.tag = _tag;
    }

    modifier noNull(string memory _string) {
        if (_string.isEqual("")) {
            revert CletNameService__Empty();
        }
        if (_string.hasEmptyString() == true) {
            revert CletNameService__Empty();
        }
        _;
    }

    modifier notEmpty(string memory _string) {
        if (_string.isEqual("")) {
            revert CletNameService__Empty();
        }
        _;
    }

    modifier isNameOwner(address _address) {
        if (_address != msg.sender) {
            revert CletNameService__Unauthorized();
        }
        _;
    }

    modifier isValidator() {
        if (msg.sender != VALIDATOR) {
            revert CletNameService__Unauthorized();
        }
        _;
    }
}
