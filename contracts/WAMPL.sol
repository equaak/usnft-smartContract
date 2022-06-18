// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.4;

import {IERC20} from "openzeppelin-contracts-4.4.1/contracts/token/ERC20/IERC20.sol";

import {SafeERC20} from "openzeppelin-contracts-4.4.1/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts-4.4.1/contracts/token/ERC20/ERC20.sol";
// solhint-disable-next-line max-line-length
import {ERC20Permit} from "openzeppelin-contracts-4.4.1/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @title Wusnft (Wrapped usnft).
 *
 * @dev A fixed-balance ERC-20 wrapper for the usnft rebasing token.
 *
 *      Users deposit usnft into this contract and are minted wusnft.
 *
 *      Each account's wusnft balance represents the fixed percentage ownership
 *      of usnft's market cap.
 *
 *      For exusnfte: 100K wusnft => 1% of the usnft market cap
 *        when the usnft supply is 100M, 100K wusnft will be redeemable for 1M usnft
 *        when the usnft supply is 500M, 100K wusnft will be redeemable for 5M usnft
 *        and so on.
 *
 *      We call wusnft the "wrapper" token and usnft the "underlying" or "wrapped" token.
 */
contract Wusnft is ERC20, ERC20Permit {
    using SafeERC20 for IERC20;

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The maximum wusnft supply.
    uint256 public constant MAX_Wusnft_SUPPLY = 10000000 * (10**18); // 10 M

    //--------------------------------------------------------------------------
    // Attributes

    /// @dev The reference to the usnft token.
    address private immutable _usnft;

    //--------------------------------------------------------------------------

    /// @param usnft The usnft ERC20 token address.
    /// @param name_ The wusnft ERC20 name.
    /// @param symbol_ The wusnft ERC20 symbol.
    constructor(
        address usnft,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        _usnft = usnft;
    }

    //--------------------------------------------------------------------------
    // Wusnft write methods

    /// @notice Transfers usnfts from {msg.sender} and mints wusnfts.
    ///
    /// @param wusnftes The amount of wusnfts to mint.
    /// @return The amount of usnfts deposited.
    function mint(uint256 wusnftes) external returns (uint256) {
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _deposit(_msgSender(), _msgSender(), usnftes, wusnftes);
        return usnftes;
    }

    /// @notice Transfers usnfts from {msg.sender} and mints wusnfts,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param wusnftes The amount of wusnfts to mint.
    /// @return The amount of usnfts deposited.
    function mintFor(address to, uint256 wusnftes) external returns (uint256) {
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _deposit(_msgSender(), to, usnftes, wusnftes);
        return usnftes;
    }

    /// @notice Burns wusnfts from {msg.sender} and transfers usnfts back.
    ///
    /// @param wusnftes The amount of wusnfts to burn.
    /// @return The amount of usnfts withdrawn.
    function burn(uint256 wusnftes) external returns (uint256) {
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _withdraw(_msgSender(), _msgSender(), usnftes, wusnftes);
        return usnftes;
    }

    /// @notice Burns wusnfts from {msg.sender} and transfers usnfts back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param wusnftes The amount of wusnfts to burn.
    /// @return The amount of usnfts withdrawn.
    function burnTo(address to, uint256 wusnftes) external returns (uint256) {
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _withdraw(_msgSender(), to, usnftes, wusnftes);
        return usnftes;
    }

    /// @notice Burns all wusnfts from {msg.sender} and transfers usnfts back.
    ///
    /// @return The amount of usnfts withdrawn.
    function burnAll() external returns (uint256) {
        uint256 wusnftes = balanceOf(_msgSender());
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _withdraw(_msgSender(), _msgSender(), usnftes, wusnftes);
        return usnftes;
    }

    /// @notice Burns all wusnfts from {msg.sender} and transfers usnfts back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @return The amount of usnfts withdrawn.
    function burnAllTo(address to) external returns (uint256) {
        uint256 wusnftes = balanceOf(_msgSender());
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _withdraw(_msgSender(), to, usnftes, wusnftes);
        return usnftes;
    }

    /// @notice Transfers usnfts from {msg.sender} and mints wusnfts.
    ///
    /// @param usnftes The amount of usnfts to deposit.
    /// @return The amount of wusnfts minted.
    function deposit(uint256 usnftes) external returns (uint256) {
        uint256 wusnftes = _usnfteToWusnfte(usnftes, _queryusnftSupply());
        _deposit(_msgSender(), _msgSender(), usnftes, wusnftes);
        return wusnftes;
    }

    /// @notice Transfers usnfts from {msg.sender} and mints wusnfts,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param usnftes The amount of usnfts to deposit.
    /// @return The amount of wusnfts minted.
    function depositFor(address to, uint256 usnftes) external returns (uint256) {
        uint256 wusnftes = _usnfteToWusnfte(usnftes, _queryusnftSupply());
        _deposit(_msgSender(), to, usnftes, wusnftes);
        return wusnftes;
    }

    /// @notice Burns wusnfts from {msg.sender} and transfers usnfts back.
    ///
    /// @param usnftes The amount of usnfts to withdraw.
    /// @return The amount of burnt wusnfts.
    function withdraw(uint256 usnftes) external returns (uint256) {
        uint256 wusnftes = _usnfteToWusnfte(usnftes, _queryusnftSupply());
        _withdraw(_msgSender(), _msgSender(), usnftes, wusnftes);
        return wusnftes;
    }

    /// @notice Burns wusnfts from {msg.sender} and transfers usnfts back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @param usnftes The amount of usnfts to withdraw.
    /// @return The amount of burnt wusnfts.
    function withdrawTo(address to, uint256 usnftes) external returns (uint256) {
        uint256 wusnftes = _usnfteToWusnfte(usnftes, _queryusnftSupply());
        _withdraw(_msgSender(), to, usnftes, wusnftes);
        return wusnftes;
    }

    /// @notice Burns all wusnfts from {msg.sender} and transfers usnfts back.
    ///
    /// @return The amount of burnt wusnfts.
    function withdrawAll() external returns (uint256) {
        uint256 wusnftes = balanceOf(_msgSender());
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _withdraw(_msgSender(), _msgSender(), usnftes, wusnftes);
        return wusnftes;
    }

    /// @notice Burns all wusnfts from {msg.sender} and transfers usnfts back,
    ///         to the specified beneficiary.
    ///
    /// @param to The beneficiary wallet.
    /// @return The amount of burnt wusnfts.
    function withdrawAllTo(address to) external returns (uint256) {
        uint256 wusnftes = balanceOf(_msgSender());
        uint256 usnftes = _wusnfteTousnfte(wusnftes, _queryusnftSupply());
        _withdraw(_msgSender(), to, usnftes, wusnftes);
        return wusnftes;
    }

    //--------------------------------------------------------------------------
    // Wusnft view methods

    /// @return The address of the underlying "wrapped" token ie) usnft.
    function underlying() external view returns (address) {
        return _usnft;
    }

    /// @return The total usnfts held by this contract.
    function totalUnderlying() external view returns (uint256) {
        return _wusnfteTousnfte(totalSupply(), _queryusnftSupply());
    }

    /// @param owner The account address.
    /// @return The usnft balance redeemable by the owner.
    function balanceOfUnderlying(address owner) external view returns (uint256) {
        return _wusnfteTousnfte(balanceOf(owner), _queryusnftSupply());
    }

    /// @param usnftes The amount of usnft tokens.
    /// @return The amount of wusnft tokens exchangeable.
    function underlyingToWrapper(uint256 usnftes) external view returns (uint256) {
        return _usnfteToWusnfte(usnftes, _queryusnftSupply());
    }

    /// @param wusnftes The amount of wusnft tokens.
    /// @return The amount of usnft tokens exchangeable.
    function wrapperToUnderlying(uint256 wusnftes) external view returns (uint256) {
        return _wusnfteTousnfte(wusnftes, _queryusnftSupply());
    }

    //--------------------------------------------------------------------------
    // Private methods

    /// @dev Internal helper function to handle deposit state change.
    /// @param from The initiator wallet.
    /// @param to The beneficiary wallet.
    /// @param usnftes The amount of usnfts to deposit.
    /// @param wusnftes The amount of wusnfts to mint.
    function _deposit(
        address from,
        address to,
        uint256 usnftes,
        uint256 wusnftes
    ) private {
        IERC20(_usnft).safeTransferFrom(from, address(this), usnftes);

        _mint(to, wusnftes);
    }

    /// @dev Internal helper function to handle withdraw state change.
    /// @param from The initiator wallet.
    /// @param to The beneficiary wallet.
    /// @param usnftes The amount of usnfts to withdraw.
    /// @param wusnftes The amount of wusnfts to burn.
    function _withdraw(
        address from,
        address to,
        uint256 usnftes,
        uint256 wusnftes
    ) private {
        _burn(from, wusnftes);

        IERC20(_usnft).safeTransfer(to, usnftes);
    }

    /// @dev Queries the current total supply of usnft.
    /// @return The current usnft supply.
    function _queryusnftSupply() private view returns (uint256) {
        return IERC20(_usnft).totalSupply();
    }

    //--------------------------------------------------------------------------
    // Pure methods

    /// @dev Converts usnfts to wusnft amount.
    function _usnfteToWusnfte(uint256 usnftes, uint256 totalusnftSupply)
        private
        pure
        returns (uint256)
    {
        return (usnftes * MAX_Wusnft_SUPPLY) / totalusnftSupply;
    }

    /// @dev Converts wusnfts amount to usnfts.
    function _wusnfteTousnfte(uint256 wusnftes, uint256 totalusnftSupply)
        private
        pure
        returns (uint256)
    {
        return (wusnftes * totalusnftSupply) / MAX_Wusnft_SUPPLY;
    }
}
