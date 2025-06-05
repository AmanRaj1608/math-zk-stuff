// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECAdd {
    // takes two (x1, y1) and (x2, y2) points on the curve and returns the sum of the two points
    function add(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public view returns (uint256, uint256) {
        // precompile address for ECADD on BN254 (alt_bn128) G1 curve
        address ecAddAddress = address(6);

        // encode the function selector and arguments
        // x1, y1, x2, y2 each 32 bytes
        bytes memory payload = abi.encode(x1, y1, x2, y2);

        // call the precompile
        (bool success, bytes memory result) = ecAddAddress.staticcall(payload);

        if (!success) {
            revert("ECAdd failed");
        }

        // decode the result
        (uint256 x3, uint256 y3) = abi.decode(result, (uint256, uint256));
        return (x3, y3);
    }
}
