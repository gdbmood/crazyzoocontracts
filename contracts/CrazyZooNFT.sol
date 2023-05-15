// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

interface IZooToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract CrazyZooNFT is ERC721, ERC721Burnable, AccessControl {

    using Strings for uint256;


    uint256 public lemurMinId ;
    uint256 public lemurMaxId ;

    uint256 public rhinoMinId ;
    uint256 public rhinoMaxId ;

    uint256 public gorillaMinId ;
    uint256 public gorillaMaxId ;

    uint256 public lemurIdCounter ;
    uint256 public rhinoIdCounter ;
    uint256 public gorillaIdCounter ;


    uint256[3] public nftPrices = [250000000000000000000, 250000000000000000000, 250000000000000000000];
    uint256[3] public extraMintAmount = nftPrices;

    IERC20 public USDTtoken;
    address public feeCollector;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public chargeFeeOnMint = true;
    bool public directMintEnabled = false;

    string public baseURI;
    mapping(uint256 => string) public cids;

    event NewFees(uint256[] indexed fees);
    event NewUSDTtoken(address newToken);
    event DirectMinting(bool indexed enabled);
    event FeeStatusUpdated(bool indexed newStatus);
    event NewFeeCollector(address indexed newFeeCollector);
    event NewCID(uint256 indexed index, string indexed newCid);
    event TransferFee(address indexed sender,address indexed feeCollector,uint256 indexed fee);
    event mint(address indexed to, uint256 indexed currentId);

    constructor(IERC20 _USDTtoken, address _feeCollector) ERC721("Crazy Zoo NFT", "CZN"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        USDTtoken = _USDTtoken;
        feeCollector = _feeCollector;
    }

    function setRange(uint256 min, uint256 diff) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(min > 0, "min should be greater than 0");
        require(
            diff > min,
            "number of nfts in a single class should be greater than minimum"
        );
        require(lemurIdCounter < 1);
        require(rhinoIdCounter < 1);
        require(gorillaIdCounter < 1);
        lemurMinId = min;
        lemurMaxId = diff;
        lemurIdCounter = lemurMinId;

        rhinoMinId = lemurMaxId + 1;
        rhinoMaxId = diff * 2;
        rhinoIdCounter = rhinoMinId;

        gorillaMinId = rhinoMaxId + 1;
        gorillaMaxId = diff * 3;
        gorillaIdCounter = gorillaMinId;
        

    }

    function setFees(
        uint256[] calldata fees
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {

        uint256 len = nftPrices.length;

        //  The loop iterates over the array of _tokenIds
        for (uint256 i; i < len; ++i) {

        require(
            fees[i] != 0 ,
            "Fee Can Not Be Zero"
        );
            nftPrices[i] = fees[i];
        }

        emit NewFees(fees);
    }

    function setUSDTToken(address newToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newToken != address(0), "Address Can Not Be Zero Address");
        USDTtoken = IERC20(newToken);
        emit NewUSDTtoken(newToken);
    }

    function setDirectMinting(bool setValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        directMintEnabled = setValue;
        emit DirectMinting(setValue);
    }

    function getDirectMinting()
        external
        view
        returns(bool)
    {
        return directMintEnabled;
    }


    function setMintFeeStatus(bool setValue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        chargeFeeOnMint = setValue;
        emit FeeStatusUpdated(chargeFeeOnMint);
    }

      function getMintFeeStatus()  
        external
        view
        returns(bool) {
        return chargeFeeOnMint;
    }

    function setFeeCollector(address _newCollector)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _newCollector != address(0),
            "Collector Can Not Be Zero Address"
        );
        feeCollector = _newCollector;
        emit NewFeeCollector(_newCollector);
    }

    function getFeeCollector()
        external
        view
        returns(address)
    {
        return feeCollector;   
    }

    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _uri;
    }

    function getBaseURI()
        public
        view
        returns(string memory)
    {
        return baseURI;
    }

    function setCid(uint256 index, string memory _cid)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(index > 0 && index < 4, "Invalid CID Index");
        require(bytes(_cid).length > 0, "CID Can Not Be Empty String");
        cids[index] = _cid;

        emit NewCID(index, _cid);
    }

    //approval
    function safeMint(address to, uint256 tokenId) public {
        // checks if the provided tokenId falls within a specific range. purpose of the range is to ensure that only valid tokenIds can be minted.
        checkIdRange(tokenId);
        // checks if the caller of the safeMint function has the MINTER_ROLE role. The hasRole function is provided by the OpenZeppelin Access Control library and checks if a given address has a specific role.
        if (hasRole(MINTER_ROLE, _msgSender())) {
            // to mint the specified tokenId to the provided to address.
            // make sure that the address that receives the token implements the onERC721Received function from the ERC721 standard.
            // helps ensure that the transfer is completed safely and that the receiving contract can handle the incoming token.
            _safeMint(to, tokenId);
        } else {
            // checks if the directMintEnabled flag is set to true. If it is, then the user can mint tokens directly without the MINTER_ROLE role.
            if (directMintEnabled) {
                // checks if the chargeFeeOnMint flag is set to true. If it is, then a fee is charged to the user before the token is minted.
                if (chargeFeeOnMint) {
                    //  calculates the fee to be charged based on the provided tokenId
                    uint256 fee = getFeeForId(tokenId);

                    //usdc transfer
                    // transfer the fee from the user's account to the feeCollector account.
                    transferFee(msg.sender, feeCollector, fee);
                    emit TransferFee(msg.sender, feeCollector, fee);

                    _safeMint(to, tokenId);
                } else {
                    // If the chargeFeeOnMint flag is not set to true, then this code block is executed.
                    _safeMint(to, tokenId);
                }
            } else {
                // If directMintEnabled is set to false, then this code block is executed.
                revert("You Can Not Mint Now");
            }
        }
    }

    function mintLemur(address to) public {
        require(to != address(0), "Can Not Mint To Zero Address");
        require(
            lemurIdCounter <= lemurMaxId,
            "No more Lemurs available for minting"
        );

        uint256 currentId = lemurIdCounter;

        require(
            currentId >= lemurMinId && currentId <= lemurMaxId,
            "Lemur Id Out Of Range"
        );

        safeMint(to, currentId);
        lemurIdCounter = lemurIdCounter + 1;
    }

    function mintRhino(address to) public {
        require(to != address(0), "Can Not Mint To Zero Address");
        require(
            rhinoIdCounter <= rhinoMaxId,
            "No more Rhinos available for minting"
        );

        uint256 currentId = rhinoIdCounter;

        require(
            currentId >= rhinoMinId && currentId <= rhinoMaxId,
            "Rhino Id Out Of Range"
        );

        safeMint(to, currentId);
        rhinoIdCounter = rhinoIdCounter + 1;
    }

    //This function mints a new Gorilla NFT and assigns it to the specified address (to)
    function mintGorilla(address to) public {
        require(to != address(0), "Can Not Mint To Zero Address");
        require(
            gorillaIdCounter <= gorillaMaxId,
            "No more Gorillas available for minting"
        );

        uint256 currentId = gorillaIdCounter;

        require(
            currentId >= gorillaMinId && currentId <= gorillaMaxId,
            "Gorilla Id Out Of Range"
        );
        
        // emit mint(to, currentId);
        safeMint(to, currentId);
        gorillaIdCounter = gorillaIdCounter + 1;
    }

    function transferFee(
        address from,
        address to,
        uint256 amount
    ) public {
        // checks if the to address is not zero
        require(to != address(0), "Can Not Transfer To Zero Address");
        // checks if the amount to be transfer is not zero
        if (amount == 0) {
            return;
        }
        //checks if the contract has been approved to spend the required amount of tokens by the from address
        require(
            // ZooToken is likely an address of a token contract that implements the IZooToken interface.
            // By passing ZooToken as an argument to IZooToken, the contract can interact with the IZooToken interface of the token contract at the specified address.
            USDTtoken.allowance(from, address(this)) >= amount,
            "Approve Contract For Payment"
        );
        USDTtoken.transferFrom(from, to, amount);
    }

    function getTotalMintedNfts(uint256 _id) public view returns (uint256) {
        if (_id == 0) {
            return lemurIdCounter;
        } else if (_id == 1) {
            return rhinoIdCounter;
        } else if (_id == 2) {
            return gorillaIdCounter;
        } else {
            revert("Id Out Of Range");
        }
    }

    function getFeeForIndex(uint256 _index) public view returns (uint256) {
        return nftPrices[_index];
    }

    function getIndexForId(uint256 _id) public view returns (uint256) {
        if (_id >= lemurMinId && _id <= lemurMaxId) {
            return 1;
        } else if (_id >= rhinoMinId && _id <= rhinoMaxId) {
            return 2;
        } else if (_id >= gorillaMinId && _id <= gorillaMaxId) {
            return 3;
        } else {
            revert("Id Out Of Range");
        }
    }

    function checkIdRange(uint256 _tokenId) internal view {
        require(
            //  checks if the _tokenId falls within the range of lemurMinId to lemurMaxId.
            (_tokenId >= lemurMinId && _tokenId <= lemurMaxId) ||
                // checks if the _tokenId falls within the range of rhinoMinId to rhinoMaxId.
                (_tokenId >= rhinoMinId && _tokenId <= rhinoMaxId) ||
                // checks if the _tokenId falls within the range of gorillaMinId to gorillaMaxId.
                (_tokenId >= gorillaMinId && _tokenId <= gorillaMaxId),
            "Id Out Of Range"
        );
    }

    // checks if the _id parameter is within the range, then return the corresponding fees
    function getFeeForId(uint256 _id) public view returns (uint256) {
        if (_id >= lemurMinId && _id <= lemurMaxId) {
            return nftPrices[0];
        } else if (_id >= rhinoMinId && _id <= rhinoMaxId) {
            return nftPrices[1];
        } else if (_id >= gorillaMinId && _id <= gorillaMaxId) {
            return nftPrices[2];
        } else {
            revert("Id Out Of Range");
        }
    }

    function getExtraAmount(uint256 _id)public view returns(uint256){
        if (_id >= lemurMinId && _id <= lemurMaxId) {
            return extraMintAmount[0];
        } else if (_id >= rhinoMinId && _id <= rhinoMaxId) {
            return extraMintAmount[1];
        } else if (_id >= gorillaMinId && _id <= gorillaMaxId) {
            return extraMintAmount[2];
        } else {
            revert("Id Out Of Range");
        }
    }
    function getCid(uint256 _tokenId) internal view returns (string memory) {
        string memory cid;
        if (_tokenId >= lemurMinId && _tokenId <= lemurMaxId) {
            cid = cids[1];
        } else if (_tokenId >= rhinoMinId && _tokenId <= rhinoMaxId) {
            cid = cids[2];
        } else if (_tokenId >= gorillaMinId && _tokenId <= gorillaMaxId) {
            cid = cids[3];
        }
        return cid;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(_tokenId);
        string memory tokenCid = getCid(_tokenId);

        string memory baseURI_ = getBaseURI();
        return
            (bytes(baseURI).length > 0 && bytes(tokenCid).length > 0)
                ? string(
                    abi.encodePacked(
                        baseURI_,
                        tokenCid,
                        "/",
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    

    // The purpose of the supportsInterface function is to check whether a given interface is supported by the contract. In Solidity, an interface
    //is defined by its unique four-byte identifier, known as an interface ID.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
