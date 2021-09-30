// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './SvgCore.sol';
// import './SvgWidgets.sol';
interface ISvgWidgets {
    function gaugeVBar(bytes memory) external view returns (bytes memory);
    function gaugeVBar(bytes memory, bytes memory) external view returns (bytes memory);
    function gaugeHBar(bytes memory) external view returns (bytes memory);
    function gaugeHBar(bytes memory, bytes memory) external view returns (bytes memory);
    function gaugeArc(bytes memory) external view returns (bytes memory);
    function gaugeArc(bytes memory, bytes memory) external view returns (bytes memory);
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
    enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }

    bytes constant bgRect = hex'000000ffff';

    constructor(address _SvgWigets, address _sTools){
        SvgWidgets = ISvgWidgets(_SvgWigets);
        sTools   = ISvgTools(_sTools);
    }

    function a_aave(uint _health, uint8 _health_percent) public view returns(string memory){
        bytes memory bgSize = hex'0000006488'; //with opt byte 
        bytes memory gauge = abi.encodePacked(
            sTools.autoLinearGradient( // gradient
                hex'20000064',
                abi.encodePacked(
                    sTools.getColor('Aave1'),
                    sTools.getColor('Aave2')
                ),
                'grBg',
                ''
            ),
            SvgWidgets.gaugeVBar('GL1'),
            SvgCore.use(
                hex'00010a',
                '#GL1',
                abi.encodePacked(
                    'id="gl1" stroke-dasharray="',
                    _health_percent.toString(),
                    ' 100"'
                )
            )
        );
        return string(
            abi.encodePacked(
                SvgCore.startSvg(bgSize, 'height="400"'),
                SvgCore.rect(bgSize, 'id="rectBg" rx="5"'),
                gauge,
                '<style>text{font-family:sans;}</style>',
                SvgCore.style(svgStyle(1, 0, "#rectBg", "#grBg", '')),
                SvgCore.text(hex'301a', 'Aave', 'font-size="small"'),
                SvgCore.text(hex'1a4a', 'Health Factor', 'font-size="x-small"'),
                SvgCore.text(hex'227a', sTools.toEthTxt(_health, 2), 'class="hf"'),
                SvgCore.endSvg()
            )
        );
    }

    function a_testall() public view returns(string memory){
         return string(
            abi.encodePacked(
                SvgCore.startSvg(hex'000000ffff', ''),
                a_testStyles(),
                a_testShapes(),
                a_testWidgets(),
                a_testAnimate(),
                SvgCore.use(hex'006e64', '#GL2','id="gl2" stroke-dasharray="48,100"'),
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
        bytes memory gaugesSymbols = abi.encodePacked(
                // Returns the symbols
                SvgWidgets.gaugeArc('G1', c1),
                SvgWidgets.gaugeArc('G2', c2),
                SvgWidgets.gaugeHBar('GL2', c1),
                SvgWidgets.gaugeVBar('GL1')
        );
        return string(
            abi.encodePacked(
                gaugesSymbols,
                // Set the gauges at 10,10 and 110,10 , fill them at 98
                SvgCore.use(hex'000a0a', '#G1', 'id="g1" stroke-dasharray="99,100"'),
                SvgCore.use(hex'006e0a', '#G2', 'id="g2" stroke-dasharray="98,100"'),
                SvgCore.use(hex'002e64', '#GL1','id="gl1" stroke-dasharray="98,100"'),
                SvgCore.use(hex'006e64', '#GL2','id="gl2" stroke-dasharray="98,100"'),
                // Animate gauges from 0 to 98
                SvgCore.animate(hex'02000a5864', '#g1', 'stroke-dasharray', 3, 'begin="click"'),
                SvgCore.animate(hex'02000a5864', '#g2', 'stroke-dasharray', 3, 1, ''),
                SvgCore.animate(hex'02000a5864', '#gl2', 'stroke-dasharray', 3, 1, '')
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
                SvgCore.text(hex'0a12', 'Click the Gauge!', '')
        ));
    }


    function a_testAnimate() public view returns(string memory){
        return string(abi.encodePacked(
            //Hex value contains:
            // [0] number of elements per tuple
            // [1:] tuples
            // #c1 is the element to animate, 'r' attributeName
            // Todo: encode dur, repeatCount and begin
            SvgCore.animate(hex'011d1f091d', '#c1', 'r', 3, ''),
            SvgCore.animate(hex'01011f090108041c01', '#c1', 'stroke-width', 13, ''),
            SvgCore.animate(hex'08ff33cc77aa4400332288441a1abb6464ff33cc77aa440033', '#p2', 'points', 8, ''),
            SvgCore.animateTransform(hex'03003444ff4433', '#g1', AnimTransfType.rotate, 19, 'begin="click"')
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

    function a_testEnum() public view returns (ActionChoices) {
        ActionChoices choice;
        return ActionChoices.GoLeft;
    }
}
