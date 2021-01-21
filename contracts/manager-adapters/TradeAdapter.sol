// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {BaseAdapter} from "./BaseAdapter.sol";
import {TreasuryManager} from "../TreasuryManager.sol";

import {PreciseUnitMath} from "../lib/PreciseUnitMath.sol";

import {ITradeModule} from "../interfaces/ITradeModule.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";


contract TradeAdapter is BaseAdapter {
    using PreciseUnitMath for uint256;
    ITradeModule public module;

    constructor(
        ISetToken _setToken,
        TreasuryManager _manager,
        ITradeModule _module

    )
        public BaseAdapter(_setToken, _manager)
    {
        module = _module;
    }

    /**
     * @dev Only gov. Will revert if the destinationToken isn't on the allowed list
     *
     * @param _integrationName             The name of the integration to interact with
     * @param _sourceToken                 The address of the token to spend
     * @param _sourceAmount                The source amount to trade
     * @param _destinationToken            The token to get
     * @param _minimumDestinationAmount    The minimum amount to get
     * @param _data                        Calldata needed for the integration
     */
    function trade(
        address /* unused */, // Left here purely so that ABI is exactly the same as the trade module
        string memory _integrationName,
        address _sourceToken,
        uint256 _sourceAmount,
        address _destinationToken,
        uint256 _minimumDestinationAmount,
        bytes memory _data
    )
        external
        onlyGovOrSubGov
    {
        require(
            manager.isTokenAllowed(_destinationToken),
            "TradeAdapter::trade: _destinationToken is not on the allowed list"
        );
        
        bytes memory encoded = abi.encodeWithSelector(
            module.trade.selector,
            setToken,
            _integrationName,
            _sourceToken,
            _sourceAmount,
            _destinationToken,
            _minimumDestinationAmount,
            _data
        );

        manager.interactModule(address(module), encoded);
    }
}
