// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {TreasuryManager} from "../TreasuryManager.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";

contract BaseAdapter {
    TreasuryManager public manager;
    ISetToken public setToken;

    constructor(ISetToken _setToken, TreasuryManager _manager) public {
        setToken = _setToken;
        manager = _manager;
    }

    modifier onlyGovOrSubGov() {
        require(
            manager.gov() == msg.sender || manager.isSubGov(msg.sender),
            "BaseAdapter::onlyGovOrSubGov: Invalid permissions"
        );
        _;
    }

    modifier onlyGov() {
        require(
            manager.gov() == msg.sender,
            "BaseAdapter::onlyGov: Invalid permissions"
        );
        _;
    }
}
