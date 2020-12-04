// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {BaseAdapter} from "./BaseAdapter.sol";
import {TreasuryManager} from "../TreasuryManager.sol";

import {IStreamingFeeModule} from "../interfaces/IStreamingFeeModule.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";

contract StreamingFeeAdapter is BaseAdapter {
    IStreamingFeeModule public immutable module;

    constructor(
        ISetToken _setToken,
        TreasuryManager _manager,
        IStreamingFeeModule _module
    ) public BaseAdapter(_setToken, _manager){
        module = _module;
    }

    /**
     * @dev Only can invoke modules
     *
     * @param _newFeeRecipient           New fee recipient address
     */
    function updateFeeRecipient(address _newFeeRecipient)
        external
        onlyCanInvokeModules
    {
        bytes memory encoded = abi.encode(
            module.updateFeeRecipient.selector,
            address(setToken),
            _newFeeRecipient
        );
        manager.interactModule(address(module), encoded);
    }

    /**
     * @dev Only can invoke modules
     *
     * @param _newFee                    New streaming fee 18 decimal precision
     */
    function updateStreamingFee(uint256 _newFee)
        external
        onlyCanInvokeModules
    {
        bytes memory encoded = abi.encode(
            module.updateStreamingFee.selector,
            address(setToken),
            _newFee
        );
        manager.interactModule(address(module), encoded);
    }
}
