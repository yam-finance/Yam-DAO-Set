// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import {SafeMath} from "./lib/SafeMath.sol";

import {SubGoverned} from "./lib/SubGoverned.sol";
import {PreciseUnitMath} from "./lib/PreciseUnitMath.sol";
import {Address} from "./lib/Address.sol";

import {ISetToken} from "./interfaces/ISetToken.sol";
import {IStreamingFeeModule} from "./interfaces/IStreamingFeeModule.sol";
import {ITradeModule} from "./interfaces/ITradeModule.sol";
import {IWrapModule} from "./interfaces/IWrapModule.sol";

contract TreasuryManager is SubGoverned {
    using PreciseUnitMath for uint256;
    using Address for address;

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the portfolio manager
     */
    modifier onlyPortfolioManager() {
        require(msg.sender == portfolioManager, "Must be portfolio manager");
        _;
    }

    /* ============ State Variables ============ */

    /** @notice  Set token this contract manages             */
    ISetToken public setToken;

    /** @notice  Fee module for the set token                */
    IStreamingFeeModule public feeModule;

    /** @notice  Trade module for the set token              */
    ITradeModule public tradeModule;

    /** @notice  Wrap module for the set token               */
    IWrapModule public wrapModule;

    /** @notice  portfolio manager for the set token         */
    address public portfolioManager;

    /** @notice  mapping of all allowed tokens               */
    mapping(address => bool) public tokenAllowlist;

    /** @notice  mapping of allowed adapters                 */
    mapping(address => mapping(bytes32 => bool)) public adapterAllowlist;

    constructor(
        ISetToken _setToken,
        IStreamingFeeModule _feeModule,
        ITradeModule _tradeModule,
        IWrapModule _wrapModule,
        address _gov,
        address _portfolioManager,
        address[] memory _tokenAllowlist
    ) 
        public
    {
        setToken = _setToken;
        feeModule = _feeModule;
        tradeModule = _tradeModule;
        wrapModule = _wrapModule;
        gov = _gov;
        portfolioManager = _portfolioManager;
        for (uint256 index = 0; index < _tokenAllowlist.length; index++) {
            tokenAllowlist[_tokenAllowlist[index]] = true;
        }
    }

    /* ============ External Functions ============ */

    /**
     * @dev Gov or SubGov ONLY
     *
     * @notice                        Updates the porfolio manager address
     * @param _portfolioManager       Address of new portfolio manager
     */
    function setPortfolioManager(address _portfolioManager)
        external
        onlyGovOrSubGov
    {
        portfolioManager = _portfolioManager;
    }

    /**
     * @dev Portfolio Manager ONLY
     *
     * @notice              Sets portfolio manager to 0x0. This is in case the portfolio manager believes their address is compromised
     */
    function abdicatePortfolioManager()
        external 
        onlyPortfolioManager
    {
        portfolioManager = address(0x0);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @notice                     Updates the streaming fee for the set
     * @param _streamingFee        The new fee to set for this set
     */
    function setStreamingFee(uint256 _streamingFee)
        external
        onlyGovOrSubGov 
    {
        feeModule.updateStreamingFee(setToken, _streamingFee);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @notice                     Updates whether a token can be purchased in the DAO
     * @param _token               The asset to enable/disable on the allowed list
     * @param _tradable            Whether the asset should be tradable
     */
    function setTokenTradable(address _token, bool _tradable)
        external
        onlyGovOrSubGov
    {
        tokenAllowlist[_token] = _tradable;
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @notice                      Updates the manager of the SetToken
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) 
        external 
        onlyGovOrSubGov
    {
        setToken.setManager(_newManager);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @param _module           New module to add
     */
    function addModule(address _module) 
        external
        onlyGovOrSubGov
    {
        setToken.addModule(_module);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module)
        external
        onlyGovOrSubGov
    {
        setToken.removeModule(_module);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactModule(address _module, bytes calldata _data)
        external
        onlyGovOrSubGov
    {
        require(_module != address(feeModule), "Must not be fee module");

        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * @dev Portfolio Manager ONLY. Will revert if the destinationToken isn't on the allowed list. Will revert if _exchangeName is not allowed
     *
     * @param _integrationName             The name of the integration to interact with
     * @param _sourceToken                 The address of the token to spend
     * @param _sourceAmount                The source amount to trade
     * @param _destinationToken            The token to get
     * @param _minimumDestinationAmount    The minimum amount to get
     * @param _data                        Calldata needed for the integration
     */
    function trade(
        string memory _integrationName,
        address _sourceToken,
        uint256 _sourceAmount,
        address _destinationToken,
        uint256 _minimumDestinationAmount,
        bytes memory _data
    )
        external
        onlyPortfolioManager
    {
        require(
            tokenAllowlist[_destinationToken],
            "TreasuryManager::trade: _destinationToken is not on the allowed list"
        );
        require(
            adapterAllowlist[address(tradeModule)][sha256(abi.encodePacked(_integrationName))], 
            "TreasuryManager::trade: _integrationName is not allowed"
        );
        // NOTE: should I be doing this? I assume so since totalSupply could change if it isn't transformed on-chain
        uint256 transformedSourceAmount = _sourceAmount.preciseDiv(setToken.totalSupply());
        tradeModule.trade(
            setToken,
            _integrationName,
            _sourceToken,
            transformedSourceAmount,
            _destinationToken,
            _minimumDestinationAmount,
            _data
        );
    }

    /**
     * @dev Portfolio Manager ONLY. This function will revert if the wrappedToken isn't on the allowed list. Will revert if _integrationName isn't on the allowed list
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
        onlyPortfolioManager
    {
        require(
            tokenAllowlist[_wrappedToken],
            "TreasuryManager::wrap: _wrappedToken is not on the allowed list"
        );
        require(
            adapterAllowlist[address(wrapModule)][sha256(abi.encodePacked(_integrationName))], 
            "TreasuryManager::wrap: _integrationName is not allowed"
        );
        wrapModule.wrap(
            setToken,
            _underlyingToken,
            _wrappedToken,
            _underlyingUnits,
            _integrationName
        );
    }

    /**
     * @dev Portfolio Manager ONLY. This function will revert if _udnerlyingToken isn't on the allowed list. This function will revert if the underlyingToken isn't on the allowed list
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
        onlyPortfolioManager
    {
        require(
            tokenAllowlist[_underlyingToken],
            "TreasuryManager::wrap: _underlyingToken is not on the allowed list"
        );
        require(
            adapterAllowlist[address(wrapModule)][sha256(abi.encodePacked(_integrationName))], 
            "TreasuryManager::wrap: _integrationName is not whitelisted"
        );
        wrapModule.unwrap(
            setToken,
            _underlyingToken,
            _wrappedToken,
            _wrappedUnits,
            _integrationName
        );
    }
    

    /**
     * @dev Gov or SubGov ONLY. Updates whether a module+integration combo are allowed
     *
     * @param _module                    The module to allow this adapter with
     * @param _adapterName               The adapter to allow with this module
     */
    function setAdapterAllowed(
        address _module,
        string memory _adapterName,
        bool allowed
    )
        external
        onlyGovOrSubGov
    {
        adapterAllowlist[_module][sha256(abi.encodePacked(_adapterName))] = allowed;

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
        feeModule.updateFeeRecipient(setToken, _newFeeRecipient);
    }

    /**
     * @dev Gov or SubGov ONLY
     *
     * @param _newFee           New streaming fee 18 decimal precision 
     */
    function updateStreamingFee(uint256 _newFee)
        external
        onlyGovOrSubGov
    {
        feeModule.updateStreamingFee(setToken, _newFee);
    }
}
