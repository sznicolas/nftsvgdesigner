// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './Base64.sol';
import './SvgCore.sol';

interface ISvgWidgets {
    function gaugeVBar() external view returns (bytes memory);
    function gaugeVBar(bytes memory) external view returns (bytes memory);
    function gaugeVBar(bytes memory, bytes memory) external view returns (bytes memory);
    function gaugeHBar(bytes memory) external view returns (bytes memory);
    function gaugeHBar(bytes memory, bytes memory)
    external view returns (bytes memory);
    function includeSymbolGaugeArc(bytes memory) external view returns (bytes memory);
    function includeSymbolGaugeV(bytes memory) external view returns (bytes memory);
    function includeSymbolSFLogo(bytes memory) external view returns (bytes memory); 
    function gaugeArc(bytes memory, bytes memory)
    external view returns (bytes memory);
    function autoVGauge(bytes memory, uint, bytes memory)
    external view returns (bytes memory);
}

interface ISvgTools {
    function getColor(string memory) external view returns (bytes memory);
    function getColor(string memory, uint8 )
    external view returns (bytes memory);
    function toEthTxt(uint256, uint8) external pure returns (bytes memory);
    function autoLinearGradient(bytes memory, bytes memory, bytes memory)
    external view returns (bytes memory);
    function autoLinearGradient(bytes memory, bytes memory, bytes memory, bytes memory)
    external view returns (bytes memory);
    function startSvgRect(bytes memory, bytes memory, bytes memory)
    external view returns (bytes memory);
    function round2Txt(uint256, uint8, uint8)
    external pure returns (bytes memory);
}

// Superfluid Interfaces
interface ISCFA {
    function getAccountFlowInfo( address token, address account) external view 
    returns ( uint256, int96, uint256, uint256);
}

interface ISuperToken {
    function balanceOf(address) external view returns (uint256);
}

// Aave LendingPool Interface
interface IAaveLP {
    function getUserAccountData(address) external view
    returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

contract Indicators is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    event NewIndicator(uint256 tokenId);

    ISvgWidgets svgWidgets ;
    ISvgTools   sTools ;
    ISCFA sCFA;
    IAaveLP sALP;
    mapping (uint256 => uint256) internal idToService;
    

    struct STAddresss {
        bytes stName;
        address addr;
    }

    STAddresss[] stAddress;
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for uint96;
    using Strings for uint8;

    uint256 constant maxSupply = 50000; 
    uint256 constant price = 10 ether;
    // box size 0,0,110,136
    bytes constant bgSize = hex'00006e88';
    Counters.Counter private _tokenIdCounter;

    constructor(address _SvgWigets, address _sTools) ERC721('Indicators', 'IDC') {
        svgWidgets = ISvgWidgets(_SvgWigets);
        sTools   = ISvgTools(_sTools);
        // polygon 
        sCFA = ISCFA(0x6EeE6060f715257b970700bc2656De21dEdF074C);
        stAddress.push(STAddresss('MATICx', 0x3aD736904E9e65189c3000c7DD2c8AC8bB7cD4e3));
        stAddress.push(STAddresss('ETHx', 0x27e1e4E6BC79D93032abef01025811B7E4727e85));
        stAddress.push(STAddresss('USDCx', 0xCAa7349CEA390F89641fe306D93591f87595dc1F));
        stAddress.push(STAddresss('DAIx', 0x1305F6B6Df9Dc47159D12Eb7aC2804d4A33173c2));
        stAddress.push(STAddresss('WBTCx', 0x4086eBf75233e8492F1BCDa41C7f2A8288c2fB92));
        
        sALP = IAaveLP(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    }

    function svgBase64(uint256 _tokenId) public view returns(string memory) {
        return (
            string(
                abi.encodePacked(
                    'data:image/svg+xml;base64,',
                    Base64.encode(svgRaw(_tokenId))
                )
            )
        );
    }

    // For each SuperToken:
    //      retreives the flow rate
    //      if negative :
    //          retreives the owner's balance
    //          calculates the time left (in 10th of day) before empty.

    function buildSuperFluidView(uint256 _tokenId) internal view returns(bytes memory) {
        bytes memory symbol_id = abi.encodePacked('superfluid_sg', _tokenId.toString());
        int96 flowRate;
        uint256 remainingDays; // stored in 10th of days 
        bytes memory gaugeColor; 
        // X coordinates for display
        uint8 coordX = 10;
        bytes memory svgPart = abi.encodePacked(
            svgWidgets.includeSymbolGaugeV(symbol_id), // define the gauge symbol
            svgWidgets.includeSymbolSFLogo('sfl'), 
            SvgCore.startSvg(
                hex'00002828',
                'width="15" height="10" x="92" y="5"'
            ),
            '<a href="https://app.superfluid.finance/dashboard">',
            SvgCore.use(
                hex'000000', // noopts, x,y=0,0
                '#sfl', //symbol id (href)
                ''
            ),
            '</a>',
            SvgCore.endSvg()
        );

        address owner = this.ownerOf(_tokenId);
        for (uint8 i = 0 ; i < stAddress.length ; i++) { 
            bytes memory flowTxt;

            (, flowRate,,) = sCFA.getAccountFlowInfo(stAddress[i].addr, owner);
            if (flowRate >= 0) {
                continue;
            }
            bytes memory gaugeId = abi.encodePacked('a', _tokenId.toString(), stAddress[i].stName);
            remainingDays =  uint256(
                ISuperToken(stAddress[i].addr).balanceOf(owner)
                / (uint96(-flowRate) * 8640 )
            );
            uint8 percent = uint8(remainingDays > 300 ? 100 : remainingDays / 10);
            if (percent > 50) {
                gaugeColor = sTools.getColor('SFGreen');
            } else {
                gaugeColor = sTools.getColor('SFRed');
            }

            svgPart = abi.encodePacked(
                svgPart,
                SvgCore.text(
                    abi.encodePacked(coordX + 10, uint8(120)),
                    stAddress[i].stName,
                    ''
                ),
                SvgCore.text(
                    abi.encodePacked(coordX + 10, uint8(124)),
                    abi.encodePacked(
                        // Calculate the days left before the balance gets to zero,
                        // transform it in byte x.y days (8640 sec is a 10th of a day)
                        sTools.round2Txt(
                            remainingDays,
                            1, // there is one decimal is this number
                            1  // precision: one decimal 
                        ),
                        'd'
                    ),
                    ''
                )
            );
            svgPart = abi.encodePacked(
                svgPart,
                SvgCore.use(
                    abi.encodePacked(hex'00', coordX, uint8(10)), // noopts, coords
                    abi.encodePacked('#', symbol_id), //target to display
                    abi.encodePacked(
                        'id="',
                        gaugeId,
                        '" stroke-dasharray="',
                        percent.toString(),
                        ' 100"'
                    )
                ),
                SvgCore.style(
                    svgStyle(
                        0,
                        10,
                        abi.encodePacked('#', gaugeId),
                        '', // don't fill the shape
                        gaugeColor // fills the stroke
                    )
                ),
                SvgCore.animate(
                    abi.encodePacked(hex'02000a', percent, uint8(100)),
                    abi.encodePacked('#', gaugeId),
                    'stroke-dasharray',
                    2, // duration
                    1, // repeat count
                    ''
                )
            );
            coordX += 18;
        }
        return svgPart;
    }

    function buildAaveView(uint256 _tokenId) internal view returns(bytes memory) {
        uint256 health;
        bytes memory symbol_id = abi.encodePacked('aave_sg', _tokenId.toString());
        (,,,,,health) = sALP.getUserAccountData(this.ownerOf(_tokenId));
        uint8 percent;
       //Health factor to percent : if hf == 1 : 0% ; if hf >= 3 : 100%
        if (health / 10**18 > 3) {
            percent = 100;
        }else {
            percent = uint8((health / 10**16) / 3);
        }
        return abi.encodePacked(
            svgWidgets.includeSymbolGaugeArc( // loads the gauge symbol
                symbol_id
            ),
            sTools.autoLinearGradient( // define the gauge colors
                abi.encodePacked(
                        sTools.getColor('Aave1'),
                        sTools.getColor('Aave2')
                ),
                'graave',
                ''
            ),
            SvgCore.use( // display a gauge 
                hex'00000f', //noopts, x=0, y=15
                abi.encodePacked('#', symbol_id), //target to display
                abi.encodePacked( // object params
                    'id="aave_g',
                    _tokenId.toString(),
                    '" stroke-dasharray="',
                    percent.toString(),
                    ' 100"'
                )
            ),
            SvgCore.style(
                svgStyle(
                    2,
                    10,
                    abi.encodePacked('#aave_g', _tokenId.toString()),
                    '', // don't fill the shape
                    '#graave' // gradient id, fills the stroke
                ),
                'stroke-linecap:round;'
            ),
            SvgCore.text(
                hex'3739', // coords 
                'Health Factor', // text
                ''
            ),
            SvgCore.text(
                hex'374a', // coords 
                sTools.round2Txt(health, 18, 2), // text
                'style="font-size:20px"'
            ),
            SvgCore.animate(
                abi.encodePacked(hex'02000a', percent, uint8(100)),
                abi.encodePacked('#aave_g', _tokenId.toString()),
                'stroke-dasharray',
                2, // duration
                1, // repeat count
                ''
            )
        );
    }
    
    function svgRaw(uint256 _tokenId) public view returns (bytes memory) {
        bytes memory svgPart;
        svgStyle memory bgRect = svgStyle(
            0,
            2,
            "#rectBg",
            sTools.getColor('GhostWhite'),
            sTools.getColor('Navy')
        );
        if (idToService[_tokenId] == 0) {
            svgPart = buildSuperFluidView(_tokenId);
        } else {
            svgPart = buildAaveView(_tokenId);
        }
        return abi.encodePacked(
                sTools.startSvgRect(
                    bgSize,
                    'height="400" style="font-family:sans;font-size:4px;text-anchor:middle"',
                    'id="rectBg" rx="3"'
                ),
                SvgCore.style(bgRect),
                svgPart,
                SvgCore.endSvg()
        );
    }

    function createToken(uint256 _qty, uint256 _buildType) external payable {
        require(maxSupply > _tokenIdCounter.current() + _qty, 'Exceed max supply');
        require(_buildType < 2, 'type must be 0 or 1');
        require(_qty * price == msg.value, "Ether amount is not correct");

        for (uint i = 0; i < _qty; i++){
            uint256 id = _tokenIdCounter.current();
            _safeMint(msg.sender, id);
            idToService[id] = _buildType;
            emit NewIndicator(id);
            _tokenIdCounter.increment();
        }
    }

    // The following functions are overrides required by Solidity.

    function withdraw() public onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}('');
		require(success, 'Withdrawal failed');
    }
    receive() external payable {}
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require (_exists(_tokenId), "Unknown tokenId");
        bytes memory service;
        if (idToService[_tokenId] == 0) {
            service = "SuperFluid";   
        } else {
            service = "Aave";
        }
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "service":"',
                            service,
                            '", "image": "',
                            svgBase64(_tokenId),
                            '"}'
                        )
                    )
                ) 
            )
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
