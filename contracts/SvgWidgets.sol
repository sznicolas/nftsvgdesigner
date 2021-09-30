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
    ISvgTools   SvgTools ;
    // path defines an arc
    bytes constant gaugeArcPath = hex'004d0a324128280000016432';
    bytes constant gaugeHLine   =  hex'0009096409';
    bytes constant gaugeVLine   =  hex'0009640909';
    bytes constant gaugeStyleStr = 'stroke-linecap="round" pathLength="100" ';

    constructor(address _SvgTools){
        SvgTools   = ISvgTools(_SvgTools);
    }

    /*  ---------------- Symbols ---------- */

    // Creates style for gauge background
    function gaugeBgStyle(bytes memory _id) internal view returns (svgStyle memory) {
        return svgStyle(
            0,  // no option
            10, // stroke width 10
            abi.encodePacked('#', 'bg', _id), // id
            '', // no fill
            SvgTools.getColor('DarkGrey') // stroke color
        );
    }

    function gaugeFgStyle(bytes memory _id)
    internal pure returns (svgStyle memory) {
        return svgStyle(
            2,
            9,
            abi.encodePacked('#', 'fg', _id), // id
            '',
            abi.encodePacked('#', 'grfg', _id) // gradiendid
        );
    }
    function defaultGaugeGradient() internal view returns (bytes memory) {
            return abi.encodePacked(
                    SvgTools.getColor('Red'),
                    SvgTools.getColor('Yellow'),
                    SvgTools.getColor('Green')
            );
    }

    // Gauge1 is a semi-circle gauge 
    // pass a number between 0 and 100 to fill the gauge
    // Optional: pass a gradient def to fill the gauge
    // Uses default Red to Green gradient
    function gaugeArc(
        bytes memory _id
    ) external view returns (bytes memory) {
        return _gaugeArc(
            _id,
            defaultGaugeGradient()
        );
    }

    function gaugeArc(
        bytes memory _id,
        bytes memory _grad
    ) external view returns (bytes memory) {
        return _gaugeArc(
            _id,
            _grad
        );
    }

    function gaugeStyleBgCustom(bytes memory _id)
    internal pure returns (bytes memory) {
        return abi.encodePacked(
            gaugeStyleStr,
            'stroke-dasharray="100, 100" id="bg',
           _id,
            '"' 
        );
    }

    function gaugeStyleFgCustom(bytes memory _id)
    internal pure returns (bytes memory) {
        return abi.encodePacked(
            gaugeStyleStr,
            'id="fg',
           _id,
            '"' 
        );
    }
    function _gaugeArc(
        bytes memory _id,
        bytes memory _grad
    ) internal view returns (bytes memory) {
        return SvgCore.symbol(
            _id,    
            abi.encodePacked(
                SvgCore.path(
                    gaugeArcPath,
                    gaugeStyleBgCustom(_id)
                ),
                SvgCore.path(
                    gaugeArcPath,
                    gaugeStyleFgCustom(_id)
                ),
                SvgTools.autoLinearGradient(
                    _grad,
                    abi.encodePacked('grfg', _id),
                    ''
                ),
                SvgCore.style(
                    gaugeBgStyle(_id),
                    ''
                ),
                SvgCore.style(gaugeFgStyle(_id), '')
            ) 
        );
    } 

    function gaugeHBar(
        bytes memory _id
    ) external view returns (bytes memory) {
        return _gaugeHBar(
            _id,
            defaultGaugeGradient()
        );
    }

    function gaugeHBar(
        bytes memory _id,
        bytes memory _grad
    ) external view returns (bytes memory) {
        return _gaugeHBar(
            _id,
            _grad
        );
    }

    function _gaugeHBar(
        bytes memory _id,
        bytes memory _grad
    ) internal view returns (bytes memory) {
        return SvgCore.symbol(
            _id,    
            abi.encodePacked(
                SvgCore.line(
                    gaugeHLine,
                    gaugeStyleBgCustom(_id)
                ),
                SvgCore.line(
                    gaugeHLine,
                    gaugeStyleFgCustom(_id)
                ),
                SvgTools.autoLinearGradient(
                    _grad,
                    abi.encodePacked('grfg', _id),
                    ''
                ),
                SvgCore.style(
                    gaugeBgStyle(_id),
                    ''
                ),
                SvgCore.style(gaugeFgStyle(_id), '')
            ) 
        );
    }

    function gaugeVBar(
        bytes memory _id
    ) external view returns (bytes memory) {
        return _gaugeVBar(
            _id,
            defaultGaugeGradient()
        );
    }

    function gaugeVBar(
        bytes memory _id,
        bytes memory _grad
    ) external view returns (bytes memory) {
        return _gaugeVBar(
            _id,
            _grad
        );
    }

    function _gaugeVBar(
        bytes memory _id,
        bytes memory _grad
    ) internal view returns (bytes memory) {
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
                SvgTools.autoLinearGradient(
                    hex'00000064', // turn the gradient to 0,0 0,100
                    _grad,
                    abi.encodePacked('grfg', _id),
                    ''
                ),
                SvgCore.style(
                    gaugeBgStyle(_id),
                    ''
                ),
                SvgCore.style(gaugeFgStyle(_id), '')
            ) 
        );
    }
}
