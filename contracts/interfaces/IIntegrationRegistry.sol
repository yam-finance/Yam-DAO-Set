// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IIntegrationRegistry {
    function addIntegration(
        address _module,
        string memory _name,
        address _adapter
    )
        external;
}