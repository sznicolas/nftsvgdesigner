// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// Global Enums and Structs

enum AnimTransfType { translate, scale, rotate, skewX, skewY }

struct svgStyle {
    uint8 conf; 
    uint8 stroke_width;
    bytes element; // target element to apply the style
    bytes fill;    // rgba or plain id string
    bytes stroke;  // rgba or plain id string
}

// Part: Base64

/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// Part: IAaveLP

// Aave LendingPool Interface
interface IAaveLP {
    function getUserAccountData(address) external view
    returns (uint256, uint256, uint256, uint256, uint256, uint256);
}

// Part: ISCFA

// Superfluid Interfaces
interface ISCFA {
    function getAccountFlowInfo( address token, address account) external view 
    returns ( uint256, int96, uint256, uint256);
}

// Part: ISuperToken

interface ISuperToken {
    function balanceOf(address) external view returns (uint256);
}

// Part: ISvgTools

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

// Part: ISvgWidgets

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

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/Address

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/Counters

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/IERC165

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/IERC721Receiver

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/Strings

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/IERC721

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: SvgCore

library SvgCore {

    using Strings for uint256;
    using Strings for uint8;

    // Open <svg> tag
    // _vBSize defines the viewBox in 4 bytes
    //   [0] x
    //   [1] y
    //   [2] length
    //   [3] width
    // accepts custom attributes in _customAttributes
    function startSvg(
        bytes memory _vBSize,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg ',
            'viewBox="',
            stringifyIntSet(_vBSize, 0, 4),
            '" xmlns="http://www.w3.org/2000/svg" ',
            _customAttributes,
            '>'
        );
    }

    // Close </svg> tag
    function endSvg(
    ) public pure returns (bytes memory) {
        return('</svg>');
    }

    // <g _customAttributes></g> tag encloses _b
    function defs(
        bytes memory _b,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<g ',
            _customAttributes,
            '>',
            _b,
            '</g>'
        );
    }
    // <defs></defs> tag encloses _b
    function defs(
        bytes memory _b
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<defs>',
            _b,
            '</defs>'
        );
    }
    // returns a <symbol id=...>_content</symbol>
    function symbol(
        bytes memory _id,
        bytes memory _content
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<symbol id="',
            _id,
            '">',
            _content,
            '</symbol>'
        );
    }

    // <mask id="_id">_b<mask> tag encloses _b
    // accepts custom attributes in _customAttributes
    function mask(
        bytes memory _b,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<mask ',
            _customAttributes,
            '>',
            _b,
            '</mask>'
        );
    }

    // Takes 4 bytes starting from the given offset
    // Returns css' 'rgba(r,v,b,a%)'
    // so alpha should be between 0 and 100
    function toRgba(
        bytes memory _rgba,
        uint256 offset
    ) public pure returns (bytes memory){

        return abi.encodePacked(
            "rgba(",
            byte2uint8(_rgba, offset).toString(), ",",
            byte2uint8(_rgba, offset + 1).toString(), ",",
            byte2uint8(_rgba, offset + 2).toString(), ",",
            byte2uint8(_rgba, offset + 3).toString(),
            "%)"
        );
    }

    // defines a style for '_element' class or id string (eg. '#iprefix_1') 
    // colors are defined in 4 bytes ; red,green,blue,alpha OR url(#id)
    // then if set stroke color (RGBA or #id),
    // then if set stroke-width
    // see idoc about svgStyle.conf in the struct def.
    // note: As "_element" is a free string you can pass "svg" for a default style
    function style(
        svgStyle memory _style
    ) public pure returns (bytes memory) {
        return style(_style, '');
    }
    function style(
        svgStyle memory _style,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
            bytes memory attributes; 

            attributes = abi.encodePacked(
                '<style>', 
                _style.element, '{fill:');
            if (_style.conf & 1 == 1) {
                attributes = abi.encodePacked(
                    attributes,
                    'url(',
                    _style.fill,
                    ');'
                );
            } else {
                if (_style.fill.length == 4) {
                    attributes = abi.encodePacked(
                        attributes,
                        toRgba(_style.fill, 0), ';'
                    );
                } else {
                    attributes = abi.encodePacked(
                        attributes,
                        'none;'
                    );
                }
            }
            if (_style.conf & 2 == 2) {
                attributes = abi.encodePacked(
                    attributes,
                    'stroke:url(',
                    _style.stroke,
                    ');'
                );
            } else {
                if (_style.stroke.length == 4) {
                    attributes = abi.encodePacked(
                        attributes,
                        'stroke:',
                        toRgba(_style.stroke, 0),
                        ';'
                    );
                }
            }
            attributes = abi.encodePacked(
                attributes,
                'stroke-width:',
                _style.stroke_width.toString(),
                ';'
            );
            return abi.encodePacked(
                attributes,
                _customAttributes,
                '}</style>'
            );
    }

    // Returns a line element.
    // _coord:
    //   [0] : General format applies
    //   [1] : x1 
    //   [2] : y1
    //   [3] : x2
    //   [4] : y2
    function line(
        bytes memory _coord,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        // add .0001 is a workaround for stroke filling
        // doesn'n work on horizontal and vertical lines
        return abi.encodePacked(
            '<line x1="',
            byte2uint8(_coord, 1).toString(),
            '.0001" y1="',
            byte2uint8(_coord, 2).toString(),
            '.0001" x2="',
            byte2uint8(_coord, 3).toString(),
            '" y2="',
            byte2uint8(_coord, 4).toString(),
                '" ',
            _customAttributes,
            endingtag(_coord)
        );
    }
    // Returns a polyline: Variable length ; "infinite" coordinates
    // _coords:
    //   [0] : General format applies
    //   [1],[2] x,y 1st point
    //   [3],[4] x,y 2nd point
    //   [5],[6] x,y 3rd point
    //   ... , ...
    // Define one or more lines depending on the number of parameters
    function polyline(
        bytes memory _coords,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {

        return abi.encodePacked(
            '<polyline  points="', 
            stringifyIntSet(_coords, 1, _coords.length - 1),
            '" ',
            _customAttributes,
            endingtag(_coords)
        );
    }

    // Returns a rectangle
    // _r:
    //   [0] : General format applies
    //   [1],[2] x,y 1st point
    //   [3],[4] width, height
    function rect(
        bytes memory _r,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {

        return abi.encodePacked(
            '<rect x="', 
            byte2uint8(_r, 1).toString(),
            '" y="',
            byte2uint8(_r, 2).toString(),
            '" width="',
            byte2uint8(_r, 3).toString(),
            '" height="',
            byte2uint8(_r, 4).toString(),
            '" ',
            _customAttributes,
            endingtag(_r)
        );
    }

    // Returns a polygon, with a variable number of points
    // _p:
    //   [0] : General format applies
    //   [1],[2] x,y 1st point
    //   [3],[4] x,y 2nd point
    //   [5],[6] x,y 3rd point
    //   ... , ...
    // Define one or more lines depending on the number of parameters
    function polygon(
        bytes memory _p,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {

        return abi.encodePacked(
            '<polygon points="',
            stringifyIntSet(_p, 1, _p.length -1),
            '" ',
            _customAttributes,
            endingtag(_p)
        );
    }

    // Returns a circle
    // _c:
    //   [0] : General format applies
    //   [1] : cx 
    //   [2] : cy Where cx,cy defines the center.
    //   [3] : r = radius
    function circle(
        bytes memory _c,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<circle ', 
            'cx="', 
            byte2uint8(_c, 1).toString(),
            '" cy="',
            byte2uint8(_c, 2).toString(),
            '" r="',
            byte2uint8(_c, 3).toString(),
            '" ',
            _customAttributes,
            endingtag(_c)
        );  
    }

    // Returns an ellipse
    // _e:
    //   [0] : General format applies
    //   [1] : cx 
    //   [2] : cy Where cx,cy defines the center.
    //   [3] : rx = X radius
    //   [4] : ry = Y radius
    function ellipse(
        bytes memory _e,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<ellipse ',
            'cx="',
            byte2uint8(_e, 1).toString(),
            '" cy="',
            byte2uint8(_e, 2).toString(),
            '" rx="',
            byte2uint8(_e, 3).toString(),
            '" ry="',
            byte2uint8(_e, 4).toString(),
            '" ',
            _customAttributes,
            endingtag(_e)
        );  
    }


    // Returns a <use href='#id' ...
    // _coord:
    //   [0] : General format applies
    //   [1],[2] x,y
    function use(
        bytes memory _coord,
        bytes memory _href,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<use ', 
            'href="',
            _href,
            '" x="',
            byte2uint8(_coord, 1).toString(),
            '" y="',
            byte2uint8(_coord, 2).toString(),
            '" ',
            _customAttributes,
            endingtag(_coord)
        );
    }

    // Returns a linearGradient
    //  _lg:
    //   [0] General format applies but adds an option:
    //   [0] if i & 128:
    //      [3] x1
    //      [4] x2
    //      [5] y1
    //      [6] y2
    //      [7..10] RGBA
    //      [11] offset %
    //      [12..15] RGBA
    //      [16] offset %
    //      [...]
    //   else: RGBA starts at [3]
    // Define a linear gradient, better used in a <defs> tag. 
    // Applied to an object with 'fill:url(#id)'
    // Then loops, offset + RGBA = 5 bytes 
    function linearGradient(
        bytes memory _lg,
        bytes memory _id,
        bytes memory _customAttributes
    ) external pure returns (bytes memory) {
        bytes memory grdata; 
        uint8 offset = 1;

        if (uint8(_lg[0]) & 128 == 128) {
            grdata = abi.encodePacked(
                'x1="',
                byte2uint8(_lg, 1).toString(),
                '%" x2="',
                byte2uint8(_lg, 2).toString(),
                '%" y1="',
                byte2uint8(_lg, 3).toString(),
                '%" y2="',
                byte2uint8(_lg, 4).toString(), '%"'
            );
            offset = 5;
        }
        grdata = abi.encodePacked(
            '<linearGradient id="',
            _id,
            '" ',
            _customAttributes,
            grdata,
            '>'
        );
        for (uint i = offset ; i < _lg.length ; i+=5) {
            grdata = abi.encodePacked(
                grdata,
                '<stop offset="',
                byte2uint8(_lg, i).toString(),
                '%" stop-color="',
                toRgba(_lg, i+1),
                '" id="',
                _id,
                byte2uint8(_lg, i).toString(),
                '"/>'
            );
        }
        return abi.encodePacked(grdata, '</linearGradient>');
    }

    // Returns a <text ...>_text</text> block
    // Non standard ; _b only contains coordinates.
    function text(
        bytes memory _b,
        bytes memory _text,
        bytes memory _customAttributes
    ) external pure returns (bytes memory) {
        return abi.encodePacked(
            '<text x="', 
            byte2uint8(_b, 0).toString(),
            '" y="',
            byte2uint8(_b, 1).toString(),
            '" ',
            _customAttributes,
            '>',
            _text,
            '</text>'
        );

    }

    // Returns animate
    // Non standard function.
    // _b contains the 'values' Svg field.
    //   [0] : number of byte element per tuple
    //   [1:] values
    // the tuples are separated by ';'.
    // _element refers to the id to apply the animation
    // _attr contains the attribute name set to 'attribute'
    // _element is the target element to animate
    // _attr the attribute to animate
    // _duration of the animation is in seconds
    // repeatCount's default is 'indefinite'
    function animate(
        bytes memory _b,
        bytes memory _element,
        bytes memory _attr,
        uint8 _duration,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return animate(_b, _element, _attr, _duration, 0, _customAttributes);
    }

    function animate(
        bytes memory _b,
        bytes memory _element,
        bytes memory _attr,
        uint8 _duration,
        uint8 _repeatCount,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<animate href="',
            _element,
            '" attributeName="',
            _attr,
            '" values="',
            tuples2ValueMatrix(_b),
            '" dur="',
            _duration.toString(),
            's" repeatCount="',
            repeatCount(_repeatCount),
            '" ',
            _customAttributes,
            '/>'
        );
    }

    // Returns animateTransform
    // _b is the same as in animate
    // AnimTransfType is an enum: {translate, scale, rotate, skewX, skewY}
    function animateTransform(
        bytes memory _b,
        bytes memory _element,
        AnimTransfType _type,
        uint8 _duration,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return animateTransform(_b, _element, _type, _duration, 0, _customAttributes);
    }

    function animateTransform(
        bytes memory _b,
        bytes memory _element,
        AnimTransfType _type,
        uint8 _duration,
        uint8 _repeatCount,
        bytes memory _customAttributes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<animateTransform href="',
            _element,
            '" attributeName="transform" type="',
            animTransfType(_type),
            '" dur="',
            _duration.toString(),
            's" repeatCount="',
            repeatCount(_repeatCount),
            '" values="',
            tuples2ValueMatrix(_b),
            '" ',
            _customAttributes,
            '/>'
        );
    }

    // Returns 'type' for animateTransform 
    function animTransfType(AnimTransfType _t)
    internal pure returns (bytes memory) {
        if (_t == AnimTransfType.translate) return "translate";
        if (_t == AnimTransfType.scale)     return "scale";
        if (_t == AnimTransfType.rotate)    return "rotate";
        if (_t == AnimTransfType.skewX)     return "skewX";
        if (_t == AnimTransfType.skewY)     return "skewY";
    }

    // Returns a path
    // See github's repo oh how to encode data for path
    // A Q and T are not implemented yet
    // _b:
    //   [0] : General format applies
    //   [1:] : encoded data
    function path(
        bytes memory _b,
        bytes memory _customAttributes
    ) external pure returns (bytes memory) {

        bytes memory pathdata; 
        pathdata = '<path d="';

        for (uint i = 1 ; i < _b.length ; i++) {
            if(uint8(_b[i]) == 77) {
                pathdata = abi.encodePacked(
                    pathdata, 'M',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 109) {
                pathdata = abi.encodePacked(
                    pathdata, 'm',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 76) {
                pathdata = abi.encodePacked(
                    pathdata, 'L',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 108) {
                pathdata = abi.encodePacked(
                    pathdata, 'l',
                    stringifyIntSet(_b, i+1, 2)
                );
                i += 2;
            } else if (uint8(_b[i]) == 67) {
                pathdata = abi.encodePacked(
                    pathdata, 'C',
                    stringifyIntSet(_b, i+1, 6)
                );
                i += 6;
            } else if (uint8(_b[i]) == 86) {
                pathdata = abi.encodePacked(
                    pathdata, 'V',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 118) {
                pathdata = abi.encodePacked(
                    pathdata, 'v',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 72) {
                pathdata = abi.encodePacked(
                    pathdata, 'H',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 104) {
                pathdata = abi.encodePacked(
                    pathdata, 'h',
                    byte2uint8(_b, i+1).toString()
                );
                i++;
            } else if (uint8(_b[i]) == 83) {
                pathdata = abi.encodePacked(
                    pathdata, 'S',
                    stringifyIntSet(_b, i+1, 4)
                );
                i += 4;
            } else if (uint8(_b[i]) == 115) {
                pathdata = abi.encodePacked(
                    pathdata, 's',
                    stringifyIntSet(_b, i+1, 4)
                );
                i += 4;
            } else if (uint8(_b[i]) == 65) {
                pathdata = abi.encodePacked(
                    pathdata, 'A',
                    stringifyIntSet(_b, i+1, 7)
                );
                i += 7;
            } else if (uint8(_b[i]) == 97) {
                pathdata = abi.encodePacked(
                    pathdata, 'a',
                    stringifyIntSet(_b, i+1, 7)
                );
                i += 4;
            } else if (uint8(_b[i]) == 90) {
                pathdata = abi.encodePacked(
                    pathdata, 'Z'
                );
            } else if (uint8(_b[i]) == 122) {
                pathdata = abi.encodePacked(
                    pathdata, 'z'
                );
            } else {
                pathdata = abi.encodePacked(
                    pathdata, '**' , i.toString(), '-', 
                    uint8(_b[i]).toString()
                    );
            }
        }
        return(
            abi.encodePacked(
                pathdata, '" ',
                _customAttributes,
                endingtag(_b)
            )
        );
    }
// ------ tools -----------

    // Returns the ending tag as defined in_b[3] (odd number)
    function endingtag(
        bytes memory _b
    ) pure public returns (string memory) {
        if (byte2uint8(_b,0) & 1 == 0) {
            return ' />';
        }
        return '>';
    }

    // Returns 'n' stringified and spaced uint8
    function stringifyIntSet(
        bytes memory _data,
        uint256 _offset,
        uint256 _len
    ) public pure returns (bytes memory) { 
        bytes memory res;
        require (_data.length >= _offset + _len, 'Out of range');
        for (uint i = _offset ; i < _offset + _len ; i++) {
            res = abi.encodePacked(
                res,
                byte2uint8(_data, i).toString(),
                ' '
            );
        }
        return res;
    }

    // Used by animation*, receives an array whose the first elements indicates
    // the number of tuples, and the values data
    // returns the values separated by spaces,
    // tuples separated by semicolon
    function tuples2ValueMatrix(
        bytes memory _data
    ) public pure returns (bytes memory) { 
        uint256 _len = byte2uint8(_data, 0);
        bytes memory res;

        for (uint i = 1 ; i <= _data.length - 1 ; i += _len) {
            res = abi.encodePacked(
                res,
                stringifyIntSet(_data, i, _len),
                ';'
            );
        }
        return res;

    }

    // returns a repeatCount for the animations.
    // If uint8 == 0 then indefinite loop
    // else a count of loops.
    function repeatCount(uint8 _r)
    public pure returns (string memory) {
        if (_r == 0) {
            return 'indefinite';
        } else {
            return _r.toString();
        }
    }

    // Returns one uint8 in a byte array
    function byte2uint8(
        bytes memory _data,
        uint256 _offset
    ) public pure returns (uint8) { 
        require (_data.length > _offset, 'Out of range');
        return uint8(_data[_offset]);
    }


}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/IERC721Enumerable

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/IERC721Metadata

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/ERC721

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/ERC721Enumerable

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.3.0/ERC721URIStorage

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: indicators.sol

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
