

// Convert an input of Uint8Array to a returned hex string
function uint8ArrayToHexString(uint8_array){
    // convert uint8 array to a 2 digit (1 byte) hex array.
    let hex_array = new Array;
    for(i=0; i < uint8_array.length; i++){
        hex_array.push(uint8_array[i].toString(16).padStart(2, '0'));
    }
    return hex_array.join('');
}

// inputs an integer number and converts to a hex string.
function num2hex(integer){
    return integer.toString(16);
}

// This function converts a hex string into an ArrayBuffer for hash processing.
function hex_string_to_ArrayBuffer(hexString){
    // convert to a number array representing the hex bytes.
    const hexBytesArray = new Array;
    for(let i=0; i < hexString.length; i+=2){
        hexBytesArray.push(parseInt(hexString.substring(i, i+2), 16));
    }
    return new Uint8Array(hexBytesArray);
}

// takes a buffer as input and returns a hex string
function buf2hex(buffer) { // buffer is an ArrayBuffer
  return [...new Uint8Array(buffer)]
      .map(x => x.toString(16).padStart(2, '0'))
      .join('');
}

// Takes an array of 256 bit numbers and converts each to a binary string.
function numberArrToBinaryStrArr(numberArray){
	return numberArray.map(b => b.toString(2).padStart(8, '0'));
}

// Takes a Uint8Array and returns a typeless array object
async function get256HashArray(entropy){
	const hashBuffer = await crypto.subtle.digest('SHA-256', entropy);		// hash the message
	return Array.from(new Uint8Array(hashBuffer));							// convert buffer to byte array
}

// Takes a key tree derivation notation string, like m/31h/2345/1h,
// and a mnemonic sentence for the seed.
// returns an array with index 0:privkey, 1:chain code, 2:address, 3:xprv and 4:xpub
async function derive_key_tree(key_tree_str, mnemonic, passphrase){
    // Decode the key tree, associating an index with each level.
    // build an array where the array index matches the depth level
    // each index returns a 2 deep array with 0th returning privkey
    // and 1st returning chain code.
    //
    // how do we know the root key? derive from a mnemonic sentence.
    // first build an array with the key index corresponding to the arr index.
    // use regex.
    let tree_index_arr = new Array;

    // for show
    console.log('input- mnemonic: ' + mnemonic);
    console.log('input- key_tree_str: ' + key_tree_str);

    // check validity of the mnemonic
    if( await verifyMnemonicPhrase(mnemonic) ){
        console.log('mnemonic phrase verified!');
    }else{
        console.log('mnemonic phrase INVALID!');
    }

    // load array to process index values
    tree_index_arr = key_tree_str.split('/');
    // this function should only work on private keys
    if( tree_index_arr[0] != 'm' ){
        console.log('invalid key tree format!');
    }
    // can only compute depth to 255 values past root
    if( tree_index_arr.length > 255){
        console.log('key tree invalid! max depth is 256');
    }

    // convert hardened notation into numbers and check if valid
    for(i=1; i < tree_index_arr.length; i++){
        if( /[^0-9']/.test(tree_index_arr[i]) ){
            console.log('Detected invalid key tree character!');
        // convert hardened index to number for easier use
        // do not exceed index limit
        } else if( /^[0-9]+'$/.test(tree_index_arr[i]) ){
            index = tree_index_arr[i].match(/^([0-9]+)'$/);
            if( parseInt(index) < 2**31 ){
                tree_index_arr[i] = parseInt(index) + 2**31;
            }else{
                console.log('Error: index cannot exceed 2**31-1!');
            }
        // continue, normal index is in proper form
        // do not exceed index limit
        }else if( /^[0-9]+$/.test(tree_index_arr[i]) ){
            if( parseInt(tree_index_arr[i]) < 2**31 ){
                tree_index_arr[i] = parseInt(tree_index_arr[i]);
            }else{
                console.log('Error: index cannot exceed 2**31-1!');
            }
        }else{// the 'h' is in the wrong spot
            console.log('key tree is invalid!');
        }
    }
    // tree_index_arr now holds each key depth (array index) and key index (value) as a number

    // build keypair array
    // this builds the key tree structure. starting from root, compute the next keypair
    // with which you can compute the keypair after that, and so on.
    // like mathematical induction proof. 1. can compute n 2. can compute n+1
    let keypair_arr = new Array;
    // start with root master key
    keypair_arr.push(await get_root_keypair(mnemonic, passphrase));
    console.log('root extended key: ' + await serialize_key(keypair_arr[0][1], '00' + keypair_arr[0][0]));
    // compute and store the rest
    for(j=1; j < tree_index_arr.length; j++){
        keypair_arr.push(await derive_child_privkey(keypair_arr[j-1][1], keypair_arr[j-1][0], tree_index_arr[j]));
    }
    // keypair_arr now associates the depth (array index) with a 2-deep array:
    // with depth i,
    // keypair_arr[i][0] = privkey, keypair_arr[i][1] = chain code

    // depth and return_index are numbers
    const depth = tree_index_arr.length-1;
    const return_index = tree_index_arr[depth];
    // the fingerprint is the first 4 bytes of the hash160 of the parent private key
    const parent_pubkey = await secp.getPublicKey(keypair_arr[depth-1][0], true);
    const hash160_parent = await hash160(parent_pubkey);
    const fingerprint = hash160_parent.substring(0,8);
    // return the last keypair in the array
    const return_privkey = keypair_arr[depth][0];
    const return_chain = keypair_arr[depth][1];
    const return_pubkey = await secp.getPublicKey(return_privkey, true);
    // with its address
    const return_address = await getAddress(return_pubkey);

    // convert the number into hex values of the proper length
    const depth_hex = num2hex(depth).padStart(2, '0');
    const index_hex = num2hex(return_index).padStart(8, '0');

    // serialize_key input order: chain, key, depth, index, fingerprint
    const return_xpriv = await serialize_key(return_chain, '00' + return_privkey, depth_hex, index_hex, fingerprint);
    const return_xpub = await serialize_key(return_chain, return_pubkey, depth_hex, index_hex, fingerprint);

    // build full keyset array (privkey, chain code, address, xpriv, xpub) and return it
    let full_keyset_arr = new Array;
    full_keyset_arr[0] = return_privkey;
    full_keyset_arr[1] = return_chain;
    full_keyset_arr[2] = return_address;
    full_keyset_arr[3] = return_xpriv;
    full_keyset_arr[4] = return_xpub;
    return full_keyset_arr;
}

/*
function usage:
let err = check_tree_input(key_tree_str);
if( err !== ''){
    console.log('error: ' + err);
}else{
    console.log('no error detected: ' + err);
}
*/
// returns error value on fail. returns empty string on success.
// takes a bip32 tree derivation string as input eg m/0h/1
function check_tree_input(key_tree_str){
    let tree_index_arr = new Array;
    // load array to process index values
    tree_index_arr = key_tree_str.split('/');
    // this function should only work on private keys
    if( tree_index_arr[0] != 'm' ){
        return 'invalid key tree format!';
    }
    // can only compute depth to 255 values past root
    if( tree_index_arr.length > 255){
        return 'key tree invalid! max depth is 256';
    }

    // convert hardened notation into numbers and check if valid
    for(i=1; i < tree_index_arr.length; i++){
        if( /[^0-9']/.test(tree_index_arr[i]) ){
            return 'Detected invalid key tree character!';
        // convert hardened index to number for easier use
        // do not exceed index limit
        } else if( /^[0-9]+'$/.test(tree_index_arr[i]) ){
            index = tree_index_arr[i].match(/^([0-9]+)'$/);
            if( parseInt(index) < 2**31 ){
                tree_index_arr[i] = parseInt(index) + 2**31;
            }else{
                return 'Error: index cannot exceed 2**31-1!';
            }
        // continue, normal index is in proper form
        // do not exceed index limit
        }else if( /^[0-9]+$/.test(tree_index_arr[i]) ){
            if( parseInt(tree_index_arr[i]) < 2**31 ){
                tree_index_arr[i] = parseInt(tree_index_arr[i]);
            }else{
                return 'Error: index cannot exceed 2**31-1!';
            }
        }else{// the 'h' is in the wrong spot
            return 'key tree is invalid!';
        }
    }
    return '';
}

// This overloaded function derives both child normal and hardened keys based on
// the inputted index. This follows the bip32 spec for CKD functions.
// Parent chain code and privkey are hex string inputs, index is a number.
// Indexes from 0 to 2**31-1 will derive normal children while 2**31 to 2**32-1
// will derive hardened children.
// Outputs will be a 2 deep array: index 0: child key, index 1: child chain code.
async function derive_child_privkey(parent_chain_code, parent_privkey, index) {
    // The order of the elliptic curve defined in secp256k1 is a constant.
    //const n_order_hex = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141';
    // In order to do the non hashing math in this function, we need to use a BigInt
    // to preserve all significant digits.
    //let n_order_int = BigInt('0x' + n_order_hex);
	// pull from known upkept library for consistency
    let n_order_int = secp.CURVE.n;
    // index must be in hex string for concatenation
    index_hex = num2hex(index).padStart(8, '0');
    const key = parent_chain_code;
    let intermediate_key = '';
    let data = '';
    // check if we're deriving a hardened or normal set of keys.
    console.log('inputted index: ' + index);
	console.log('index hex: ' + index_hex);
    if(index >= 2**31){
        // derive hardened child with parent private key
        data = '00' + parent_privkey + index_hex;
        console.log('index is greater than 2**31, compute hardended children');
    }else{
        // derive normal children
        let parent_pubkey = await secp.getPublicKey(parent_privkey, true);
        data = parent_pubkey + index_hex;
        console.log('index is less than 2**31, compute normal children');
    }
    //console.log('data: ' + data);
    //console.log('key: ' + key);

    intermediate_key = await hmac_sha512(data, key);
    const ikey_left = intermediate_key.substring(0,64);
    const child_chain_code = intermediate_key.substring(64,128);

    // BIP 32 specifies that derived chain codes >= the order (n) are invalid.
    // The probability of this is lower than 1 in 2**127.
    if (BigInt('0x' + child_chain_code) >= n_order_int){
        throw 'Chain code is greater than the order of the curve. Try the next index.';
    }

    // Use scalar addition here
    let child_key_int = BigInt(Number.MAX_SAFE_INTEGER);
    child_key_int = (BigInt('0x' + ikey_left) + BigInt('0x' + parent_privkey)) % n_order_int;
    let child_key_hex = num2hex(child_key_int);

    // Make sure the key is 32 bytes!
    child_key_hex = child_key_hex.padStart(64, '0');

    let children_keys = new Array;
    children_keys[0] = child_key_hex;
    children_keys[1] = child_chain_code;

    return children_keys;
}

// getAddress takes a public key in a hex string as input and
// returns a base58 encoded P2PKH (prefix 1) address.
async function getAddress(public_key){
	// first run a hash160
	const pubkey_h160_hexstr = await hash160(public_key);
	
    const data = '00' + pubkey_h160_hexstr;
    const checksum = await computeChecksum(data);
    const payload = data + checksum;
    return encode_b58(payload);
}

// takes a hex string as input
// returns a hex string
async function hash160(hex_input){
    // run a SHA256 hash on the input
    const input_buffer = hex_string_to_ArrayBuffer(hex_input);
    const hashed_buffer_256 = await crypto.subtle.digest('SHA-256', input_buffer);
    const input_uint8_arr = new Uint8Array(hashed_buffer_256);
    // Take the result of the SHA256 hash and run a ripemd160 hash on it.
    // ripemd160 takes Uint8Array and returns a Uint8Array.
    const input_h160_uint8 = await noble.ripemd160(input_uint8_arr);
    return uint8ArrayToHexString(input_h160_uint8);
}

// inputs a keypair with privkey at index zero
// outputs an address of the public key
async function get_address_from_keypair(keypair){
    const pubkey_child = await secp.getPublicKey(keypair[0], true);
    const address_child = await getAddress(pubkey_child);
    return address_child;
}

// takes a valid mnemonic as input
// outputs the root master privkey pair
async function get_root_keypair(mnemonic, passphrase){

    const seed = await computeSeed512(mnemonic, passphrase);
    const hashed_seed = await hmac_sha512(seed);
    const root_privkey = hashed_seed.substring(0,64);
    const root_chain_code = hashed_seed.substring(64,128);

    let root_keys = new Array;
    root_keys[0] = root_privkey;
    root_keys[1] = root_chain_code;
    return root_keys;
}

// Takes hex strings as input.
// Outputs the xprv key encoded in base58.
// For Master root extended keys, we start at 0 for several values.
// Default to root extended key (public and private)
async function serialize_key(chain, key, depth = '00', index = '00000000', fingerprint = '00000000'){
    let version = '';
    // Check if key is private
    if( key.substring(0,2) == '00'){
        // key is private, start encoded str with xprv
        version = '0488ADE4';
    }else{  // key is public, start encoded str with xpub
        version = '0488B21E';
    }

    const serialized = version + depth + fingerprint + index + chain + key;
    const checksum = await computeChecksum(serialized);
    let extended_key = encode_b58(serialized + checksum);
    return extended_key;
}

// Converts an inputted hex string into a base58 encoded number.
// This function is for bitcoin, so leading '00's will be converted to a 1.
function encode_b58(hex_number) {
    // Set of base58 chars
    const base58 = [1,2,3,4,5,6,7,8,9,'A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','m','n','o','p','q','r','s','t','u','v','w','x','y','z'];

    // Convert hex string into a number for processing.
    // Default numbers in java are computed to only 16 significant digits.
    let num = BigInt(Number.MAX_SAFE_INTEGER);
    // 0x tells BigInt that the hex_number is in hexadecimal
    input = '0x' + hex_number;
    num = BigInt(input);

    // We use a math trick to convert the number into base 58 that involves taking the remainder
    // of a modulus operation and integer division.
    let remainder = '';
    // Create empty string to hold encoded base58 chars.
    let encoded_buffer = '';
    while(num > 0){
        // The remainder represents the next base58 digit.
        remainder = num % BigInt(58);
        // Add the corresponding base58 digit on the left of our encoded string.
        encoded_buffer = base58[remainder] + encoded_buffer;
        // integer division
        num = num/BigInt(58);
    }

    // Bitcoin spec requires us to convert leading zero pairs to 1's.
    // When converted to a number, leading zeros are ignored.
    // Thus we can convert them to 1's from the original hex string and
    // attach them after the initial base58 encoding.
    let num_leading_zero_pairs = 0;
    const regex = /^00/g;
    while (hex_number.match(regex)){
        hex_number = hex_number.substring(2);
        num_leading_zero_pairs++;
    }
    for(i=num_leading_zero_pairs; i > 0; i--){
        encoded_buffer = '1' + encoded_buffer;
    }
    return encoded_buffer;
}

// Takes no inputs
// Returns array containing mnemonic sentence, seed, xprv respectively
async function mnemonic_gen_to_xprv (){

    const mne_sentence = await computeMnemonicPhrase();
    if( await verifyMnemonicPhrase(mne_sentence)){
        console.log('mnemonic sentence verified!');
    }else{
        console.log('mnemonic sentence INVALID!');
    }

    seed512_hex = await computeSeed512(mne_sentence);
    hmac_sha512_hashed_seed = await hmac_sha512(seed512_hex);
    private_key_256 = hmac_sha512_hashed_seed.substring(0,64);
    chain_code = hmac_sha512_hashed_seed.substring(64,128);
    xprv_key = await serialize_key(chain_code, '00' + private_key_256);

    let return_arr = new Array();
    return_arr[0] = mne_sentence;
    return_arr[1] = seed512_hex;
    return_arr[2] = xprv_key;

    return return_arr;
}

// Takes hex string as input and outputs a hex string of 4 bytes.
async function computeChecksum(payload) {

    // Encode payload data into ArrayBuffer.
    const hexArrayBuffer = hex_string_to_ArrayBuffer(payload);

    // Bitcoin base58check uses a double sha-256 hash.
    const hashBuffer256 = await crypto.subtle.digest('SHA-256', hexArrayBuffer);
    const double256 = await crypto.subtle.digest('SHA-256', hashBuffer256);
    hashHex = buf2hex(double256);
    return hashHex.substring(0,8);
}

// Takes hex string(s) as input and outputs a hex string.
// Performs the HMAC-SHA512 hash.
async function hmac_sha512(data, key){
    // If no key is given, we are computing the root extended private key
    let key_enc;
    if (typeof key == 'undefined'){
        // Encode the key.
        const key = 'Bitcoin seed';
        key_enc = new TextEncoder().encode(key);
    }else{
        // Any other input should be a hex string.
        key_enc = hex_string_to_ArrayBuffer(key);
    }

    // Encode the hex data
    const data_encoded = hex_string_to_ArrayBuffer(data);

    //set up hmac algorithm object
    hmac_algorithm_obj =
    {
        name: "HMAC",
        hash: {name: "SHA-512"}
    }

    //CryptoKey object needed for deriveBits() to perform PBKDF2.
    const imported_key = await crypto.subtle.importKey(
        "raw", // raw format of the key - should be Uint8Array
        key_enc,
        hmac_algorithm_obj,
        false, // export = false
        ["sign", "verify"] // what this key can do
    );

    // Perform the HMAC-SHA512 hash
    const signature = await crypto.subtle.sign(
        "HMAC",
        imported_key,
        data_encoded
    );

    return buf2hex(signature);
}

// Takes a mnemonic sentence and possibly a password as input.
// Outputs the computed seed in a hex string.
async function computeSeed512(mnemonicPhrase, in_password){
    if( typeof in_password !== 'undefined'){
        password = in_password;
    }else{
        password = '';
    }
	console.log('password: ' + password);
    const salt = 'mnemonic' + password;
    const normsalt = salt.normalize('NFKD', 'utf8');
    // For PBKDF2 to work properly, inputs must be in uint8 ArrayBuffer format.
    const saltArrayBuffer = new TextEncoder().encode(normsalt);
    const phraseArrayBuffer = new TextEncoder().encode(mnemonicPhrase);

    // Construct pbkdf2params object.
    const pbkdf2params_object =
        {
            "name": "PBKDF2",       // Identifies this as a pbkdf2params object.
            salt: saltArrayBuffer,  // Cryptographic salt.
            "iterations": 2048,     // Number of iterations.
            "hash": "SHA-512"       // Hash digest algorithm identifier.
        };
    //CryptoKey object needed for deriveBits() to perform PBKDF2.
    const pbkdf2_cryptokey = await crypto.subtle.importKey(
        //Format of data. Raw is used for HMAC keys.
        "raw",
        //Raw key supplied as ArrayBuffer.
        phraseArrayBuffer,
        // Dictionary object defining the type of key to import.
        "PBKDF2",
        // W3C requires this to be 'false' for PBKDF2.
        false,
        //How the key will be used.
        ["deriveBits"]

    );

    //ArrayBuffer holding 512 bits produced from PBKDF2.
    const derived_512_bits_from_PBKDF2 = await crypto.subtle.deriveBits(
        //Specific algorithm. In our case: Pbkdf2Params dictionary object.
        pbkdf2params_object,
        //CryptoKey object. For PBKDF2, comes from importKey().
        pbkdf2_cryptokey,
        //The number of bits to derive.
        512
    );

    return buf2hex(derived_512_bits_from_PBKDF2);
}

// Generate a mnemonic phrase with entropy generated from the subtlecrypto library.
// Returns a string of mnemonic words delimited by a single space.
async function computeMnemonicPhrase(){
	// Create array of 16 randomly generated 8-bit integers.
	var rand_entropy = new Uint8Array(16);
	crypto.getRandomValues(rand_entropy);

	// Create checksum from SHA-256 hash, using the first 4 bits.
	const hashArray = await get256HashArray(rand_entropy);
	// Convert array of numbers to an array of 8-bit binary strings.
	const hashBinArr = numberArrToBinaryStrArr(hashArray);
	const checksum = hashBinArr[0].substring(0,4);

    // Add the checksum to the end of the random sequence of 8-bit numbers.
    // Need to convert entropy to an untyped array for it to work.
    const entropyArray = Array.from(rand_entropy);
    const entropyAndChecksum = numberArrToBinaryStrArr(entropyArray).join('') + checksum;

    // Divide the resulting sequence into sections of 11 bits. 
    const numberWordArray = new Array;
    for(var i=0; i < entropyAndChecksum.length; i+=11){
        numberWordArray.push(entropyAndChecksum.substring(i,i+11));
    }

    // Produce 12 words representing the mnemonic code.
    const wordArray = new Array;
    for(var n=0; n < numberWordArray.length; n++){
		// Use the 11-bit numbers to index an array of 2048 predefined words.
        wordArray.push(wordListArray[parseInt(numberWordArray[n], 2)]);
    }

    return wordArray.join(' ');
}

// Returns true if verified, false otherwise.
async function verifyMnemonicPhrase(phrase){
    const phraseArray = phrase.split(' ');

    // Convert to array of 11 bit binary numbers
    indexArray = new Array;

    for(let i=0; i < phraseArray.length; i++){
        if( wordListArray.indexOf(phraseArray[i]) < 0){
            console.warn('Word: ' + phraseArray[i] + ' not found in mnemonic word list!');
            return false;
        }else{
            indexArray.push(wordListArray.indexOf(phraseArray[i]));
        }
    }
    // Convert to an array of binary strings.
    const binaryIndexArray = indexArray.map(b => b.toString(2).padStart(11, '0'));

    // Strip off checksum.
    const binaryIndexStr = binaryIndexArray.join('');
    // Capture checksum bits.
    const checksum = binaryIndexStr.slice(-4);
    // Remove checksum bits from the bits that represent the mnemonic phrase.
    const wordBitsStr = binaryIndexStr.substring(0, binaryIndexStr.length-4);
    const wordBitsArray = new Array;
    for(let i=0; i < wordBitsStr.length; i+=8){
        wordBitsArray.push(wordBitsStr.substring(i,i+8));
    }

    // Convert the 8-bit word strings into numbers.
    const entropyNumberArr = new Array;
    for(let i=0; i < wordBitsArray.length; i++){
        entropyNumberArr.push(parseInt(wordBitsArray[i], 2));
    }

    // Take the SHA-256 hash of the resulting numbers.
    const entropyBytesUint8 = new Uint8Array(entropyNumberArr);
    const hashArray = await get256HashArray(entropyBytesUint8);

    // Convert resulting hash and compare checksum bits
    const hashBinArr = numberArrToBinaryStrArr(hashArray);
    // The checksum is represented by the first 4 bits of the hash.
    const checksum_verify = hashBinArr[0].substring(0,4);
    if(checksum.localeCompare(checksum_verify) === 0){
        return true;
    }else{
        return false;
    }
}

