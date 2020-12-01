// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {BaseAdapter} from "./BaseAdapter.sol";
import {TreasuryManager} from "../TreasuryManager.sol";

import {IWrapModule} from "../interfaces/IWrapModule.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";

contract WrapAdapter is BaseAdapter {
    IWrapModule public module;

    constructor(
        ISetToken _setToken,
        TreasuryManager _manager,
        IWrapModule _module
    )
        public BaseAdapter(_setToken, _manager)
    {
        module = _module;
    }
 
    /**
     * @dev Gov or SubGov ONLY. This function will revert if the wrappedToken isn't on the allowed list
     *
     * @param _integrationName          The name of the integration to interact with
     * @param _underlyingToken          The token to wrap
     * @param _wrappedToken             The token to get after wrapping
     * @param _underlyingUnits          The amount of unlderlyingToken to wrap
     */
    function wrap(
        string memory _integrationName,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits
    )
        external
        onlyCanInvokeModules
    {
        require(
            manager.isTokenAllowed(_wrappedToken),
            "WrapAdapter::wrap: _wrappedToken is not on the allowed list"
        );
        bytes memory encoded = abi.encodeWithSelector(module.wrap.selector,
            setToken,
            _underlyingToken,
            _wrappedToken,
            _underlyingUnits,
            _integrationName
        );

        manager.interactModule(address(module), encoded);
    }

    /**
     * @dev Gov or SubGov ONLY. This function will revert if the underlyingTOken isn't on the allowed list
     *
     * @param _integrationName          The name of the integration to interact with
     * @param _underlyingToken          The underlying token to receive
     * @param _wrappedToken             The token to unwrap
     * @param _wrappedUnits             The amount of wrapped tokens to unwrap
     */
    function unwrap(
        string memory _integrationName,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedUnits
    )
        external
        onlyCanInvokeModules
    {
        require(
             manager.isTokenAllowed(_underlyingToken),
            "WrapAdapter::unwrap: _underlyingToken is not on the allowed list"
        );
        bytes memory encoded = abi.encodeWithSelector(module.unwrap.selector,
            address(setToken),
            _underlyingToken,
            _wrappedToken,
            _wrappedUnits,
            _integrationName
        );

        manager.interactModule(address(module), encoded);
    }
}
