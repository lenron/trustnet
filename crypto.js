
function buf2hex(buffer) { // buffer is an ArrayBuffer
  return [...new Uint8Array(buffer)]
      .map(x => x.toString(16).padStart(2, '0'))
      .join('');
}

function numberArrToBinaryStrArr(numberArray){
	return numberArray.map(b => b.toString(2).padStart(8, '0'));
}

async function get256HashArray(entropy){
	const hashBuffer = await crypto.subtle.digest('SHA-256', entropy);		// hash the message
	return Array.from(new Uint8Array(hashBuffer));								// convert buffer to byte array
}

async function computeSeed512(mnemonicPhrase, in_password){
	if( typeof password !== 'undefined'){
		password = in_password;
	}else{
		password = '';
	}
    const salt = 'mnemonic' + password;
	console.log(salt);
    const normsalt = salt.normalize('NFKD', 'utf8');
    // For PBKDF2 to work properly, inputs must be in uint8 ArrayBuffer format.
    const saltArrayBuffer = new TextEncoder().encode(normsalt);
    const phraseArrayBuffer = new TextEncoder().encode(mnemonicPhrase);

    // Construct pbkdf2params object.
    const pbkdf2params_object =
        {
            "name": "PBKDF2",       // Identifies this as a pbkdf2params object.
            salt: saltArrayBuffer,      // Cryptographic salt.
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

// I can't think of a reason we would need to extract the entropy bits from the mnemonic phrase.
// Besides verification. Returns true if verified, false otherwise.
async function verifyMnemonicPhrase(phrase){
	const phraseArray = phrase.split(' ');

	// Convert to array of 11 bit binary numbers
	indexArray = new Array;
	for(var i=0; i < phraseArray.length; i++){
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
	for(var i=0; i < wordBitsStr.length; i+=8){
		wordBitsArray.push(wordBitsStr.substring(i,i+8));
	}

	// Convert the 8-bit word strings into numbers.
	const entropyNumberArr = new Array;
	for(var i=0; i < wordBitsArray.length; i++){
		entropyNumberArr.push(parseInt(wordBitsArray[i], 2));
	}

	// Take the SHA-256 hash of the resulting numbers.
	const entropyBytesUint8 = new Uint8Array(entropyNumberArr);
	const hashArray = await get256HashArray(entropyBytesUint8);

	// Convert resulting hash and compare checksum bits
	const hashBinArr = numberArrToBinaryStrArr(hashArray);
	// The checksum is represented by the first 4 bits of the hash.
	const checksum_verify = hashBinArr[0].substring(0,4);
	if(checksum == checksum_verify){
		return true;
	}else{
		return false;
	}
}

