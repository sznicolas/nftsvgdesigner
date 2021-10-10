// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './SvgCore.sol';

contract SvgTools {

    using Strings for uint256;

    mapping(string => bytes) public colors;

    constructor () {
        colors['Black'] = hex'000000'; 
        colors['White'] = hex'FFFFFF'; 
        colors['SFRed'] = hex'E02020'; 
        colors['SFGreen'] = hex'10BB34'; 
        colors['Aave1'] = hex'B6509E';
        colors['Aave2'] = hex'2EBAC6';
        colors['Navy'] = hex'000080'; 
        colors['MediumBlue'] = hex'0000CD'; 
        colors['Green'] = hex'008000'; 
        colors['DarkGreen'] = hex'006400'; 
        colors['Maroon'] = hex'800000'; 
        colors['Red'] = hex'FF0000'; 
        colors['Lime'] = hex'00FF00'; 
        colors['DarkGrey'] = hex'A9A9A9'; 
        colors['Gold'] = hex'FFD700'; 
        colors['Yellow'] = hex'FFFF00'; 
        colors['Blue'] = hex'0000FF'; 
        colors['GhostWhite'] = hex'F8F8FF'; 
        colors['LightGrey'] = hex'D3D3D3'; 
        colors['DarkViolet'] = hex'9400D3'; 
    }

    /* -------------------------------------
    *  Various helpers
       ------------------------------------- */

    // starts a <sgv> tag with a rect at the same size.
    function startSvgRect(
        bytes memory _size,
        bytes memory _svgAttrs,
        bytes memory _rectAttrs
    )
    external view returns (bytes memory) {
        return abi.encodePacked(
            SvgCore.startSvg(_size, _svgAttrs),
            SvgCore.rect(
                abi.encodePacked(
                    hex'00',
                    _size),
                _rectAttrs)
        );
    }

    function getColor(string memory _colorName)
    public view returns (bytes memory) {
        require(colors[_colorName].length == 3, "Unknown color");
        return abi.encodePacked(colors[_colorName], hex'64');
    }

    function getColor(string memory _colorName, uint8 _alpha)
    public view returns (bytes memory) {
        require(colors[_colorName].length == 3, "Unknown color");
        return abi.encodePacked(colors[_colorName], _alpha);
    }
    
    // Input: array of colors (without alpha)
    // Ouputs a linearGradient
    function autoLinearGradient(
        bytes memory _colors,
        bytes memory _id,
        bytes memory _customAttributes
    )
    public view returns (bytes memory) {
        return this.autoLinearGradient('', _colors, _id, _customAttributes);
    }
    function autoLinearGradient(
        bytes memory _coordinates,
        bytes memory _colors,
        bytes memory _id,
        bytes memory _customAttributes
    )
    external view returns (bytes memory) {
        bytes memory _b;
        if (_coordinates.length > 3 ) {
            _b = abi.encodePacked(
                uint8(128),
                _coordinates
            );
        } else {
            _b = hex'00';
        }
        // Count the number of colors passed, each on 4 byte
        uint256 colorCount = _colors.length / 4;
        uint8 i = 0;
        while (i < colorCount) {
            _b = abi.encodePacked(
                _b,
                uint8(i * (100 / (colorCount - 1))) , // grad. stop %
                uint8(_colors[i*4]),
                uint8(_colors[i*4 + 1]),
                uint8(_colors[i*4 + 2]),
                uint8(_colors[i*4 + 3])
           );
           i++;
        }
        return SvgCore.linearGradient(_b, _id, _customAttributes);
    } 


    // Converts uint value to 'decimal' text
    function round2Txt(
        uint256 _value,
        uint8 _decimals,
        uint8 _prec
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            (_value / 10 ** _decimals).toString(), 
            ".",
            ( _value / 10 ** (_decimals - _prec) -
                _value / 10 ** (_decimals ) * 10 ** _prec
            ).toString()
        );
    }

}
