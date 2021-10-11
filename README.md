#NFT SVG Designer

Simplify your onchain SVG generation.

## Overview

 - [SvgCore](contracts/SvgCore.sol) provides a set of SVG primitives to design shapes and other basic objects.
 - [SvgTools](contracts/SvgTools.sol) provides a set of tools to simplify the use of the basic objects.
 - [SvgWidgets](contracts/SvgWidgets.sol) provides a set of symbol that can be rendered in you SVG scene.

### Tools
 - [svgpath2hex](tools/svgpath2hex.py) tries to compress by rounding and converts a data path to its bytes array form, which is readable by [path](https://github.com/sznicolas/nftsvgdesigner/blob/main/contracts/SvgCore.sol#L565)
 - [tokenURItoSVG](tools/tokenURItoSVG.py) extracts the base64-encoded data and metadata. Useful for debugging.

