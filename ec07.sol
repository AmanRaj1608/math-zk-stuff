// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECMul {
    // takes a point (x_in, y_in) on the curve and a scalar and returns the point (x2, y2) = scalar * (x_in, y_in)
    function mul(
        uint256 x_in,
        uint256 y_in,
        uint256 scalar
    ) public view returns (uint256, uint256) {
        // precompile address for ECMUL on BN254 (alt_bn128) G1 curve
        address ecMulAddress = address(7);

        // encode the function selector and arguments
        // x_in, y_in, scalar each 32 bytes
        bytes memory payload = abi.encode(x_in, y_in, scalar);

        // call the precompile
        (bool success, bytes memory result) = ecMulAddress.staticcall(payload);

        if (!success) {
            revert("ECMul failed");
        }

        // decode the result
        (uint256 x_out, uint256 y_out) = abi.decode(result, (uint256, uint256));
        return (x_out, y_out);
    }
}
