// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './SvgCore.sol';

interface ISvgTools {
    function getColor(string memory) external view returns (bytes memory);
    function getColor(string memory, uint8 ) external view returns (bytes memory);
    function toEthTxt(uint256, uint8) external pure returns (bytes memory);
    function autoLinearGradient(bytes memory, bytes memory, bytes memory) external view returns (bytes memory);
    function autoLinearGradient( bytes memory, bytes memory, bytes memory, bytes memory) external view returns (bytes memory);

}

contract SvgWidgets {

    using Strings for uint256;
    ISvgTools   sTools ;
    // path defines an arc
    bytes constant gaugeArcPath = hex'004d0a324128280000016432';
    bytes constant gaugeHLine   =  hex'0009096409';
    bytes constant gaugeVLine   =  hex'0009640909';
    bytes constant gaugeStyleStr = 'pathLength="100" ';
    // Compressed path data for SuperFluid logo (with prefix '00'):
    bytes constant logoSFPath  = hex'004d1f184c18184c18104c10104c10094c1f094c1f185a4d091f4c101f4c10184c09184c091f5a4d00044c0024430026022804284c2428432628282628244c2804432802260024004c0400430200000200044c00045a';

    constructor(address _sTools){
        sTools   = ISvgTools(_sTools);
    }

    /*  ---------------- Symbols ---------- */

    // returns an arc gauge <symbol> shape
    // can be displayed with <use href='#`_id`' ...
    function includeSymbolGaugeArc(
        bytes memory _id
    ) external view returns (bytes memory) {
        return SvgCore.symbol(
            _id,    
            abi.encodePacked(
                SvgCore.path( // background
                    gaugeArcPath,
                    gaugeStyleBgCustom(_id)
                ),
                SvgCore.path( // gauge's display
                    gaugeArcPath,
                    gaugeStyleFgCustom(_id)
                ),
                SvgCore.style(_gaugeBgStyle(_id), '')
            ) 
        );
    } 

    // returns a vertical bar gauge <symbol> shape
    // can be displayed with <use href='#`_id`' ...
    function includeSymbolGaugeV(
        bytes memory _id
    ) external view returns (bytes memory) {

        return SvgCore.symbol(
            _id,    
            abi.encodePacked(
                SvgCore.line(
                    gaugeVLine,
                    gaugeStyleBgCustom(_id)
                ),
                SvgCore.line(
                    gaugeVLine,
                    gaugeStyleFgCustom(_id)
                ),
                SvgCore.style(_gaugeBgStyle(_id), '')
            )
        );
    } 
    //  returns an eye symbol.
    function includeSymbolEye(
        bytes memory _id
    ) external view returns (bytes memory) {
        return SvgCore.symbol(
            _id,
            abi.encodePacked(
                SvgCore.ellipse(hex'0010100b0f', 'style="stroke:#a1830b;fill:#fff"'),
                SvgCore.circle(hex'00101006', 'id="swpupil" style="fill:#000"')
            )
        );
    }
/* Example of use:
    <use href="#eye" x="10" y="10" class="ee"/>
    <use href="#eye" x="40" y="10" class="ee" />
    <animate href="#p1" attributeName="cx" values="16;8;6;9;16" dur="2s" repeatCount="1"/>
    <symbol id="eye">
                                                             
        <ellipse  cx="16" cy="16" rx="11" ry="15" style="stroke:#a1830b; fill:#fff" />     
        <circle class="ckb" id="p1" cx="16" cy="16" r="6">                      
        </circle>
*/
    // returns Superfluid logo as a <symbol>
    // can be displayed with <use href='#`_id`' ...
    function includeSymbolSFLogo(bytes memory _id)
    public view returns (bytes memory){
        return SvgCore.symbol(
            _id,
            SvgCore.path(
                logoSFPath,
                'fill-rule="evenodd" fill="#12141E"'
            )
        );
    }

    /*  ---------------- Internal functions ---------- */
    // Returns a svgStyle for gauges background
    function _gaugeBgStyle(bytes memory _id) internal view returns (svgStyle memory) {
        return svgStyle(
            0,  // no option
            10, // stroke width 10
            abi.encodePacked('#', 'bg', _id), // id
            '', // no fill
            sTools.getColor('DarkGrey') // stroke color
        );
    }

    // Returns textual style attributes for background 
    function gaugeStyleBgCustom(bytes memory _id)
    internal pure returns (bytes memory) {
        return abi.encodePacked(
            gaugeStyleStr,
            'stroke-dasharray="100, 100" id="bg',
           _id,
            '"' 
        );
    }

    // Returns textual style attributes for the foreground 
    function gaugeStyleFgCustom(bytes memory _id)
    internal pure returns (bytes memory) {
        return abi.encodePacked(
            gaugeStyleStr,
            'id="fg',
           _id,
            '"' 
        );
    }
}
