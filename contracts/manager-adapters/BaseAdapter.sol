// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {TreasuryManager} from "../TreasuryManager.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";

contract BaseAdapter {
    TreasuryManager public manager;
    ISetToken public setToken;

    constructor(
        ISetToken _setToken,
        TreasuryManager _manager
    )
        public
    {
        setToken = _setToken;
        manager = _manager;
    }

    modifier onlyCanInvokeModules(){
        require(manager.gov() == msg.sender || manager.isSubGov(msg.sender) , "BaseAdapter::onlyCanInvokeModules: Invalid permissions");
        _;
    }
}
