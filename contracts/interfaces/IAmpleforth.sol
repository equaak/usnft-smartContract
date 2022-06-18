// pragma solidity ^0.4.24;

// Public interface definition for the Usnfte supply policy on Ethereum (the base-chain)
interface IUsnft {
    function epoch() external view returns (uint256);

    function lastRebaseTimestampSec() external view returns (uint256);

    function inRebaseWindow() external view returns (bool);

    function globalUSNFTEpochAndUSNFTSupply() external view returns (uint256, uint256);
}
