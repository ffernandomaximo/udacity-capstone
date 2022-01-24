// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC721Mintable.sol";
import "./verifier.sol";

interface IZokratesVerifier {
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    function verifyTx(Proof memory proof, uint256[2] memory input) external view returns (bool r);

}

contract SolnSquareVerifier is REERC721Token {
    struct Solution {
        address addr;
        uint256 index;
    }
    Solution[] solutions;
    //  define a mapping to store unique solutions submitted
    mapping(uint256 => Solution) uniqueSolutions;

    event SolutionAdded(address addr, uint256 index);

    IZokratesVerifier verifier;

    constructor(address contractAddress) {
        verifier = IZokratesVerifier(contractAddress);
    }

    function addSolution(address _addr, uint256 tokenId) public {
        solutions.push(Solution(_addr, tokenId));
        uniqueSolutions[tokenId] = Solution(_addr, tokenId);

        emit SolutionAdded(_addr, tokenId);
    }

    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    function mintNFT(uint256 tokenId, IZokratesVerifier.Proof memory proof, uint256[2] memory input) public {
        require(uniqueSolutions[tokenId].addr == address(0), "ERROR: SOLUTION IS NOT UNIQUE");
        
        require(verifier.verifyTx(proof, input), "ERROR: VERIFICATION FAILED. CAN'T MINT TOKEN");

        addSolution(msg.sender, tokenId);
        _mint(msg.sender, tokenId);

    }
}