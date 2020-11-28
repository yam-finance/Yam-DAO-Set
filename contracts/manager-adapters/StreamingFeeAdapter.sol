// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {SubGoverned} from "../lib/SubGoverned.sol";
import {TreasuryManager} from "../TreasuryManager.sol";
import {TokenAllowlist} from "../lib/TokenAllowlist.sol";
import {IStreamingFeeModule} from "../interfaces/IStreamingFeeModule.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";

contract StreamingFeeAdapter is SubGoverned {
    TreasuryManager public manager;
    IStreamingFeeModule public module;
    TokenAllowlist public allowlist;
    ISetToken public setToken;

    constructor(
        ISetToken _setToken,
        TreasuryManager _manager,
        IStreamingFeeModule _module,
        address _gov
    ) public {
        setToken = _setToken;
        manager = _manager;
        module = _module;
        gov = _gov;
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @param _newFeeRecipient           New fee recipient address
     */
    function updateFeeRecipient(address _newFeeRecipient)
        external
        onlyGovOrSubGov
    {
        bytes memory encoded = abi.encode(
            module.updateFeeRecipient.selector,
            address(setToken),
            _newFeeRecipient
        );
        manager.interactModule(address(module), encoded);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @param _newFee                    New streaming fee 18 decimal precision
     */
    function updateStreamingFee(uint256 _newFee) external onlyGovOrSubGov {
        bytes memory encoded = abi.encode(
            module.updateStreamingFee.selector,
            address(setToken),
            _newFee
        );
        manager.interactModule(address(module), encoded);
    }
}
