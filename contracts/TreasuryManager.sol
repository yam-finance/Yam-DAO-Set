// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {SubGoverned} from "./lib/SubGoverned.sol";
import {Address} from "./lib/Address.sol";

import {ISetToken} from "./interfaces/ISetToken.sol";

contract TreasuryManager is SubGoverned {
    using Address for address;

    /* ============ Modifiers ============ */

    /** @notice Throws if the sender is not allowed for this module */
    modifier onlyAllowedForModule(address _module, address _user){
        require(moduleAdapterAllowlist[_module][_user] || _user == gov , "TreasuryManager::onlyAllowlistedForModule: User is not allowed for module");
        _;
    }

    /* ============ State Variables ============ */

    /** @notice  Set token this contract manages                     */
    ISetToken public setToken;

    /** @notice  mapping of allowed manager adapters                 */
    mapping(address => mapping(address => bool)) public moduleAdapterAllowlist;

    /** @notice  mapping of all allowed tokens                       */
    mapping(address => bool) public tokenAllowlist;

    /* ============ Events ============ */

    event TokensAdded(address[] tokens);
    event TokensRemoved(address[] tokens);
    
    constructor(
        ISetToken _setToken,
        address _gov,
        address[] memory _allowedTokens        
    ) 
        public
    {
        setToken = _setToken;
        gov = _gov;
        for(uint256 index = 0; index < _allowedTokens.length; index++){
            tokenAllowlist[_allowedTokens[index]] = true;
            emit TokensAdded(_allowedTokens);
        }
    }

    /* ============ External Functions ============ */


    /**
     * @dev Gov ONLY
     *
     * @param _newManager           New manager to set for the set token
     */
    function setManager(address _newManager) 
        external
        onlyGov
    {
        setToken.setManager(_newManager);
    }

    /**
     * @dev Gov ONLY
     *
     * @param _module           New module to add to the set token
     */
    function addModule(address _module) 
        external
        onlyGov
    {
        setToken.addModule(_module);
    }

    /**
     * @dev Gov
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module)
        external
        onlyGov
    {
        setToken.removeModule(_module);
    }

    /**
     * @dev Only allowed for module
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactModule(address _module, bytes calldata _data)
        external
        onlyAllowedForModule(_module, msg.sender)
    {

        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * @dev Gov ONLY. Updates whether a module + adapter combo are allowed
     *
     * @param _module                    The module to allow this adapter with
     * @param _adapter                   The adapter to allow with this module
     */
    function setModuleAdapterAllowed(
        address _module,
        address _adapter,
        bool allowed
    )
        external
        onlyGov
    {
        moduleAdapterAllowlist[_module][_adapter] = allowed;
    }


    /**
     * @dev Gov ONLY. Updates whether a module + adapter combo are allowed
     *
     * @param _tokens                    The list of tokens to add
     */
    function addTokens(address[] memory _tokens)
        public
        onlyGov
    {
        for(uint256 index = 0; index < _tokens.length; index++ ){
            tokenAllowlist[_tokens[index]] = true;
        }
        emit TokensAdded(_tokens);
    }

    /**
     * @dev Gov ONLY. Updates whether a module + adapter combo are allowed
     *
     * @param _tokens                    The list of tokens to remove
     */
    function removeTokens(address[] memory _tokens)
        external
        onlyGov
    {
        for(uint256 index = 0; index < _tokens.length; index++ ){
            tokenAllowlist[_tokens[index]] = false;
        }
        emit TokensRemoved(_tokens);
    }

    /**
     * @dev Returns whether a token is allowed
     *
     * @param _token                    The token to check if it is allowed
     */
    function isTokenAllowed(address _token)
        external
        view
        returns (bool allowed)
    {
        return tokenAllowlist[_token];
    }

}
