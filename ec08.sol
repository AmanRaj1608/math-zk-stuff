// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECPairing {
    address constant PAIRING_PRECOMPILE = address(8);
    // This doesnt return the gT element, it returns a boolean
    // takes a list of points of (Pg1, Pg2) and a list of scalars (s1, s2)
    // returns a summation of the product of the points and scalars

    uint256 constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1 {
        uint256 x;
        uint256 y;
    }

    struct G2 {
        uint256 x1;
        uint256 x1_im;
        uint256 y1;
        uint256 y1_im;
    }

    // python (a,b,c,d) -> solidity (b,a,d,c)

    // 2G1 [1368015179489954701390400359078579693043519447331113978918064868415326638035, 9918110051302171585080402603319702774565515993150576347155970296011118125764]
    // 4G2 [18556147586753789634670778212244811446448229326945855846642767021074501673839, 18936818173480011669507163011118288089468827259971823710084038754632518263340, 13775476761357503446238925910346030822904460488609979964814810757616608848118, 18825831177813899069786213865729385895767511805925522466244528695074736584695]

    // e(A,B) = e(C,D)
    // 1gT = e(-A,B)*e(C,D)
    function pairing() public view returns (bool) {
        // step 1, invert A
        uint256 inv_C_y = p - C.y;
        G1 memory inv_C = G1(C.x, inv_C_y);

        // create a payload of values
        bytes memory payload = abi.encode(
            A.x,
            A.y,
            B.x1,
            B.x1_im,
            B.y1,
            B.y1_im,
            inv_C.x,
            inv_C.y,
            D.x1,
            D.x1_im,
            D.y1,
            D.y1_im
        );

        (bool success, bytes memory result) = PAIRING_PRECOMPILE.staticcall(
            payload
        );

        require(success, "sig check failed");

        bool result_bool = abi.decode(result, (bool));

        return result_bool;
    }
}
