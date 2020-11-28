// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {SubGoverned} from "../lib/SubGoverned.sol";
import {TreasuryManager} from "../TreasuryManager.sol";

contract TokenAllowlist is SubGoverned{

    /** @notice  mapping of all allowed tokens               */
    mapping(address => bool) public tokenAllowlist;

    event TokensAdded(address[] tokens);
    event TokensRemoved(address[] tokens);
    
    constructor(address _gov, address[] memory tokens)
        public
    {
      gov = _gov;
      addTokens(tokens);
    }

    function addTokens(address[] memory tokens)
        public
        onlyGovOrSubGov
    {
        for(uint256 index = 0; index < tokens.length; index++ ){
            tokenAllowlist[tokens[index]] = true;
        }
        emit TokensAdded(tokens);
    }

    function removeTokens(address[] memory tokens)
        external
        onlyGovOrSubGov
    {
        for(uint256 index = 0; index < tokens.length; index++ ){
            tokenAllowlist[tokens[index]] = false;
        }
        emit TokensRemoved(tokens);
    }

    function isAllowed(address token)
        external
        view
        returns (bool allowed)
    {
        return tokenAllowlist[token];
    }

}