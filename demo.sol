// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* For testing, a_testall() returns the whole 'scene' 
   2 contracts and 1 lib are deployed before this one.
*/

import '@openzeppelin/contracts/utils/Strings.sol';
import './SvgCore.sol';
// import './SvgWidgets.sol';
interface ISvgWidgets {
    function gauge1(bytes memory) external view returns (bytes memory);
    function gauge1(bytes memory, bytes memory) external view returns (bytes memory);
}
interface ISvgTools {
    function getColor(string memory) external view returns (bytes memory);
    function getColor(string memory, uint8 ) external view returns (bytes memory);
    function toEthTxt(uint256, uint8) external pure returns (bytes memory);
    function autoLinearGradient( bytes memory, bytes memory, bytes memory, bytes memory) external view returns (bytes memory);

}

contract Test2 {
    using Strings for uint256;
    using Strings for uint8;
    using Strings for int8;
    
    ISvgWidgets SvgWidgets ;
    ISvgTools   sTools ;

    bytes constant bgRect = hex'000000ffff';

    constructor(address _SvgWigets, address _sTools){
        SvgWidgets = ISvgWidgets(_SvgWigets);
        sTools   = ISvgTools(_sTools);
    }

    function a_testall() public view returns(string memory){
         return string(
            abi.encodePacked(
                SvgCore.startSvg(hex'000000ffff', ''),
                a_testStyles(),
                a_testShapes(),
                a_testWidgets(),
                a_testAnimate(),
                SvgCore.endSvg()
            )
        );
    }

    function a_testWidgets() public view returns(string memory){
        // Gradient gauge G1
        bytes memory c1 = abi.encodePacked(
            sTools.getColor('Aave1'),
            sTools.getColor('Aave2')
        );
        // Gradient gauge G2
        bytes memory c2 = abi.encodePacked(
            sTools.getColor('Maroon'),
            sTools.getColor('Red'),
            sTools.getColor('Gold'),
            sTools.getColor('Yellow'),
            sTools.getColor('Lime'),
            sTools.getColor('Green')
        );
        return string(
            abi.encodePacked(
                // Returns the symbols
                SvgWidgets.gauge1('G1', c1),
                SvgWidgets.gauge1('G2', c2),
                // Set the gauges at 10,10 and 110,10 , fill them at 98
                SvgCore.use(hex'000a0a', '#G1', 'id="g1" stroke-dasharray="99,100"'),
                SvgCore.use(hex'006e0a', '#G2', 'id="g2" stroke-dasharray="98,100"'),
                // Animate gauges from 0 to 98
                SvgCore.animate(hex'02000a5864', '#g1', 'stroke-dasharray', 'dur="5s" begin="click"'),
                SvgCore.animate(hex'02000a5864', '#g2', 'stroke-dasharray', 'dur="3s" ')
            )
        );
    }

    function a_testShapes() public view returns(string memory){
         return string(abi.encodePacked(
                SvgCore.rect(bgRect, 'id="r1"'),
                SvgCore.use(hex'009888', '#r1', 'id="ur1"'),
                SvgCore.polyline(hex'000064106464641000', 'id="p1"'),
                SvgCore.circle(hex'004a4a10', 'id="c1"'),
                SvgCore.ellipse(hex'001a9a1020', 'id="e1"'),
                SvgCore.polygon(hex'00ff33cc77aa440033', 'id="p2"'),
                SvgCore.linearGradient(hex'0000ff00006464882222ff', 'gr1', ''),
                SvgCore.text(hex'0a12', '', 'Click the Gauge!')
        ));
    }


    function a_testAnimate() public view returns(string memory){
        return string(abi.encodePacked(
            //Hex value contains:
            // [0] number of elements per tuple
            // [1:] tuples
            // #c1 is the element to animate, 'r' attributeName
            // Todo: encode dur, repeatCount and begin
            SvgCore.animate(hex'011d1f091d', '#c1', 'r', 'dur="3s" repeatCount="indefinite"'),
            SvgCore.animate(hex'01011f090108041c01', '#c1', 'stroke-width', 'dur="13s" repeatCount="indefinite"'),
            SvgCore.animate(hex'08ff33cc77aa4400332288441a1abb6464ff33cc77aa440033', '#p2', 'points', 'dur="8s" repeatCount="indefinite"'),
            SvgCore.animateTransform(hex'03003444ff4433', '#g1', 'rotate', 'dur="19s" begin="click"')
        ));
    }
    function a_testStyles() public view returns(string memory){
        return string(abi.encodePacked(
            SvgCore.style(svgStyle(1, 2, "#r1", "#gr1", sTools.getColor('Black'))),
            SvgCore.style(svgStyle(0, 10, "#p1", "", sTools.getColor('Lime'))),
            SvgCore.style(svgStyle(0, 1, "#p2", "", sTools.getColor('Green', 44))),
            SvgCore.style(svgStyle(0, 10, "#c1", sTools.getColor('DarkViolet', 85), sTools.getColor('Navy', 32))),
            SvgCore.style(svgStyle(0, 10, "#e1", sTools.getColor('DarkGreen', 70), sTools.getColor('MediumBlue', 89)))
        ));
    }

    // The gradients calculate an equal position whatever the number of colors passed
    function a_testAutoGrad() public view returns (string memory) {
        return string(sTools.autoLinearGradient(
                "",
                abi.encodePacked(
                    sTools.getColor("Red"),
                    sTools.getColor("Blue")
                ),
                "Idhuhu",
                ""
        ));
    }
    // with gradient positionning(0,0 100,100)
    function a_testAutoGrad2() public view returns (string memory) {
        return string(sTools.autoLinearGradient(
                hex"00006464",
                abi.encodePacked(
                    sTools.getColor("Red"),
                    sTools.getColor("Yellow"),
                    sTools.getColor("Green")
                ),
                "mygradId",
                ""
        ));
    }

}
