// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental "ABIEncoderV2";

interface ISetTokenCreator {
    function create(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        external
        returns (address);
}
