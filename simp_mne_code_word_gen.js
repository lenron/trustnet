/*
 *
 *
 * Generate Code Words from native web cryptography API
 *
 */

// 1. Create custom source of entropy - From getRandomValues

// 2. Create a checksum of the random sequence by taking the first few bits of its SHA256 hash.

// 3. Add the checksum to the end of the random sequence.

// 4. Divide the sequence into sections of 11 bits, using those to index a dictionary of 2048 predefined words.

// 5. Produce 12 to 24 words representing the mnemonic code.




