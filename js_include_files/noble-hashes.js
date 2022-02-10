(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports, require('@noble/hashes/crypto')) :
    typeof define === 'function' && define.amd ? define(['exports', '@noble/hashes/crypto'], factory) :
    (global = typeof globalThis !== 'undefined' ? globalThis : global || self, factory(global.nobleHashes = {}, global.crypto));
})(this, (function (exports, crypto) { 'use strict';

    /*! noble-hashes - MIT License (c) 2022 Paul Miller (paulmillr.com) */
    // Cast array to different type
    const u8 = (arr) => new Uint8Array(arr.buffer, arr.byteOffset, arr.byteLength);
    const u32 = (arr) => new Uint32Array(arr.buffer, arr.byteOffset, Math.floor(arr.byteLength / 4));
    // Cast array to view
    const createView = (arr) => new DataView(arr.buffer, arr.byteOffset, arr.byteLength);
    // The rotate right (circular right shift) operation for uint32
    const rotr = (word, shift) => (word << (32 - shift)) | (word >>> shift);
    const isLE = new Uint8Array(new Uint32Array([0x11223344]).buffer)[0] === 0x44;
    // There is almost no big endian hardware, but js typed arrays uses platform specific endianess.
    // So, just to be sure not to corrupt anything.
    if (!isLE)
        throw new Error('Non little-endian hardware is not supported');
    const hexes = Array.from({ length: 256 }, (v, i) => i.toString(16).padStart(2, '0'));
    /**
     * @example bytesToHex(Uint8Array.from([0xde, 0xad, 0xbe, 0xef]))
     */
    function bytesToHex(uint8a) {
        // pre-caching improves the speed 6x
        let hex = '';
        for (let i = 0; i < uint8a.length; i++) {
            hex += hexes[uint8a[i]];
        }
        return hex;
    }
    // Currently avoid insertion of polyfills with packers (browserify/webpack/etc)
    // But setTimeout is pretty slow, maybe worth to investigate howto do minimal polyfill here
    const nextTick = (() => {
        const nodeRequire = typeof module !== 'undefined' &&
            typeof module.require === 'function' &&
            module.require.bind(module);
        try {
            if (nodeRequire) {
                const { setImmediate } = nodeRequire('timers');
                return () => new Promise((resolve) => setImmediate(resolve));
            }
        }
        catch (e) { }
        return () => new Promise((resolve) => setTimeout(resolve, 0));
    })();
    // Returns control to thread each 'tick' ms to avoid blocking
    async function asyncLoop(iters, tick, cb) {
        let ts = Date.now();
        for (let i = 0; i < iters; i++) {
            cb(i);
            // Date.now() is not monotonic, so in case if clock goes backwards we return return control too
            const diff = Date.now() - ts;
            if (diff >= 0 && diff < tick)
                continue;
            await nextTick();
            ts += diff;
        }
    }



/////////
////////////////////////////////////



    function utf8ToBytes(str) {
        if (typeof str !== 'string') {
            throw new TypeError(`utf8ToBytes expected string, got ${typeof str}`);
        }
        return new TextEncoder().encode(str);
    }
    function toBytes(data) {
        if (typeof data === 'string')
            data = utf8ToBytes(data);
        if (!(data instanceof Uint8Array))
            throw new TypeError(`Expected input type is Uint8Array (got ${typeof data})`);
        return data;
    }
    function assertNumber(n) {
        if (!Number.isSafeInteger(n) || n < 0)
            throw new Error(`Wrong positive integer: ${n}`);
    }
    function assertBytes(bytes, ...lengths) {
        if (bytes instanceof Uint8Array && (!lengths.length || lengths.includes(bytes.length))) {
            return;
        }
        throw new TypeError(`Expected ${lengths} bytes, not ${typeof bytes} with length=${bytes.length}`);
    }
    function assertHash(hash) {
        if (typeof hash !== 'function' || typeof hash.create !== 'function')
            throw new Error('Hash should be wrapped by utils.wrapConstructor');
        assertNumber(hash.outputLen);
        assertNumber(hash.blockLen);
    }


    // For runtime check if class implements interface
    class Hash {
        // Safe version that clones internal state
        clone() {
            return this._cloneInto();
        }
    }

////////////////////////////////////



    // Check if object doens't have custom constructor (like Uint8Array/Array)
    const isPlainObject = (obj) => Object.prototype.toString.call(obj) === '[object Object]' && obj.constructor === Object;
    function checkOpts(def, _opts) {
        if (_opts !== undefined && (typeof _opts !== 'object' || !isPlainObject(_opts)))
            throw new TypeError('Options should be object or undefined');
        const opts = Object.assign(def, _opts);
        return opts;
    }
    function wrapConstructor(hashConstructor) {
        const hashC = (message) => hashConstructor().update(toBytes(message)).digest();
        const tmp = hashConstructor();
        hashC.outputLen = tmp.outputLen;
        hashC.blockLen = tmp.blockLen;
        hashC.create = () => hashConstructor();
        return hashC;
    }
    function wrapConstructorWithOpts(hashCons) {
        const hashC = (msg, opts) => hashCons(opts).update(toBytes(msg)).digest();
        const tmp = hashCons({});
        hashC.outputLen = tmp.outputLen;
        hashC.blockLen = tmp.blockLen;
        hashC.create = (opts) => hashCons(opts);
        return hashC;
    }
    /**
     * Secure PRNG
     */
    function randomBytes(bytesLength = 32) {
        if (crypto.crypto.web) {
            return crypto.crypto.web.getRandomValues(new Uint8Array(bytesLength));
        }
        else if (crypto.crypto.node) {
            return new Uint8Array(crypto.crypto.node.randomBytes(bytesLength).buffer);
        }
        else {
            throw new Error("The environment doesn't have randomBytes function");
        }
    }

    // prettier-ignore
    const SIGMA$1 = new Uint8Array([
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
        14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3,
        11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4,
        7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8,
        9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13,
        2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9,
        12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11,
        13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10,
        6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5,
        10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0,
        // For BLAKE2b, the two extra permutations for rounds 10 and 11 are SIGMA[10..11] = SIGMA[0..1].
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
        14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3,
    ]);
    class BLAKE2 extends Hash {
        constructor(blockLen, outputLen, opts = {}, keyLen, saltLen, persLen) {
            super();
            this.blockLen = blockLen;
            this.outputLen = outputLen;
            this.length = 0;
            this.pos = 0;
            this.finished = false;
            this.destroyed = false;
            assertNumber(blockLen);
            assertNumber(outputLen);
            assertNumber(keyLen);
            if (outputLen < 0 || outputLen > keyLen)
                throw new Error('Blake2: outputLen bigger than keyLen');
            if (opts.key !== undefined && (opts.key.length < 1 || opts.key.length > keyLen))
                throw new Error(`Key should be up 1..${keyLen} byte long or undefined`);
            if (opts.salt !== undefined && opts.salt.length !== saltLen)
                throw new Error(`Salt should be ${saltLen} byte long or undefined`);
            if (opts.personalization !== undefined && opts.personalization.length !== persLen)
                throw new Error(`Personalization should be ${persLen} byte long or undefined`);
            this.buffer32 = u32((this.buffer = new Uint8Array(blockLen)));
        }
        update(data) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            // Main difference with other hashes: there is flag for last block,
            // so we cannot process current block before we know that there
            // is the next one. This significantly complicates logic and reduces ability
            // to do zero-copy processing
            const { finished, blockLen, buffer, buffer32 } = this;
            if (finished)
                throw new Error('digest() was already called');
            data = toBytes(data);
            const len = data.length;
            for (let pos = 0; pos < len;) {
                // If buffer is full and we still have input (don't process last block, same as blake2s)
                if (this.pos === blockLen) {
                    this.compress(buffer32, 0, false);
                    this.pos = 0;
                }
                const take = Math.min(blockLen - this.pos, len - pos);
                const dataOffset = data.byteOffset + pos;
                // full block && aligned to 4 bytes && not last in input
                if (take === blockLen && !(dataOffset % 4) && pos + take < len) {
                    const data32 = new Uint32Array(data.buffer, dataOffset, Math.floor((len - pos) / 4));
                    for (let pos32 = 0; pos + blockLen < len; pos32 += buffer32.length, pos += blockLen) {
                        this.length += blockLen;
                        this.compress(data32, pos32, false);
                    }
                    continue;
                }
                buffer.set(data.subarray(pos, pos + take), this.pos);
                this.pos += take;
                this.length += take;
                pos += take;
            }
            return this;
        }
        digestInto(out) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            if (!(out instanceof Uint8Array) || out.length < this.outputLen)
                throw new Error('_Blake2: Invalid output buffer');
            const { finished, pos, buffer32 } = this;
            if (finished)
                throw new Error('digest() was already called');
            this.finished = true;
            // Padding
            this.buffer.subarray(pos).fill(0);
            this.compress(buffer32, 0, true);
            const out32 = u32(out);
            this.get().forEach((v, i) => (out32[i] = v));
        }
        digest() {
            const { buffer, outputLen } = this;
            this.digestInto(buffer);
            const res = buffer.slice(0, outputLen);
            this.destroy();
            return res;
        }
        _cloneInto(to) {
            const { buffer, length, finished, destroyed, outputLen, pos } = this;
            to || (to = new this.constructor({ dkLen: outputLen }));
            to.set(...this.get());
            to.length = length;
            to.finished = finished;
            to.destroyed = destroyed;
            to.outputLen = outputLen;
            to.buffer.set(buffer);
            to.pos = pos;
            return to;
        }
    }

    const U32_MASK64 = BigInt(2 ** 32 - 1);
    const _32n = BigInt(32);
    function fromBig(n, le = false) {
        if (le)
            return { h: Number(n & U32_MASK64), l: Number((n >> _32n) & U32_MASK64) };
        return { h: Number((n >> _32n) & U32_MASK64) | 0, l: Number(n & U32_MASK64) | 0 };
    }
    function split(lst, le = false) {
        let Ah = new Uint32Array(lst.length);
        let Al = new Uint32Array(lst.length);
        for (let i = 0; i < lst.length; i++) {
            const { h, l } = fromBig(lst[i], le);
            [Ah[i], Al[i]] = [h, l];
        }
        return [Ah, Al];
    }
    // for Shift in [0, 32)
    const shrSH = (h, l, s) => h >>> s;
    const shrSL = (h, l, s) => (h << (32 - s)) | (l >>> s);
    // Right rotate for Shift in [1, 32)
    const rotrSH = (h, l, s) => (h >>> s) | (l << (32 - s));
    const rotrSL = (h, l, s) => (h << (32 - s)) | (l >>> s);
    // Right rotate for Shift in (32, 64), NOTE: 32 is special case.
    const rotrBH = (h, l, s) => (h << (64 - s)) | (l >>> (s - 32));
    const rotrBL = (h, l, s) => (h >>> (s - 32)) | (l << (64 - s));
    // Right rotate for shift===32 (just swaps l&h)
    const rotr32H = (h, l) => l;
    const rotr32L = (h, l) => h;
    // Left rotate for Shift in [1, 32)
    const rotlSH = (h, l, s) => (h << s) | (l >>> (32 - s));
    const rotlSL = (h, l, s) => (l << s) | (h >>> (32 - s));
    // Left rotate for Shift in (32, 64), NOTE: 32 is special case.
    const rotlBH = (h, l, s) => (l << (s - 32)) | (h >>> (64 - s));
    const rotlBL = (h, l, s) => (h << (s - 32)) | (l >>> (64 - s));
    // JS uses 32-bit signed integers for bitwise operations which means we cannot
    // simple take carry out of low bit sum by shift, we need to use division.
    function add(Ah, Al, Bh, Bl) {
        const l = (Al >>> 0) + (Bl >>> 0);
        return { h: (Ah + Bh + ((l / 2 ** 32) | 0)) | 0, l: l | 0 };
    }
    // Addition with more than 2 elements
    const add3L = (Al, Bl, Cl) => (Al >>> 0) + (Bl >>> 0) + (Cl >>> 0);
    const add3H = (low, Ah, Bh, Ch) => (Ah + Bh + Ch + ((low / 2 ** 32) | 0)) | 0;
    const add4L = (Al, Bl, Cl, Dl) => (Al >>> 0) + (Bl >>> 0) + (Cl >>> 0) + (Dl >>> 0);
    const add4H = (low, Ah, Bh, Ch, Dh) => (Ah + Bh + Ch + Dh + ((low / 2 ** 32) | 0)) | 0;
    const add5L = (Al, Bl, Cl, Dl, El) => (Al >>> 0) + (Bl >>> 0) + (Cl >>> 0) + (Dl >>> 0) + (El >>> 0);
    const add5H = (low, Ah, Bh, Ch, Dh, Eh) => (Ah + Bh + Ch + Dh + Eh + ((low / 2 ** 32) | 0)) | 0;

    // Same as SHA-512 but LE
    // prettier-ignore
    const IV$2 = new Uint32Array([
        0xf3bcc908, 0x6a09e667, 0x84caa73b, 0xbb67ae85, 0xfe94f82b, 0x3c6ef372, 0x5f1d36f1, 0xa54ff53a,
        0xade682d1, 0x510e527f, 0x2b3e6c1f, 0x9b05688c, 0xfb41bd6b, 0x1f83d9ab, 0x137e2179, 0x5be0cd19
    ]);
    // Temporary buffer
    const BUF$1 = new Uint32Array(32);
    // Mixing function G splitted in two halfs
    function G1$1(a, b, c, d, msg, x) {
        // NOTE: V is LE here
        const Xl = msg[x], Xh = msg[x + 1]; // prettier-ignore
        let Al = BUF$1[2 * a], Ah = BUF$1[2 * a + 1]; // prettier-ignore
        let Bl = BUF$1[2 * b], Bh = BUF$1[2 * b + 1]; // prettier-ignore
        let Cl = BUF$1[2 * c], Ch = BUF$1[2 * c + 1]; // prettier-ignore
        let Dl = BUF$1[2 * d], Dh = BUF$1[2 * d + 1]; // prettier-ignore
        // v[a] = (v[a] + v[b] + x) | 0;
        let ll = add3L(Al, Bl, Xl);
        Ah = add3H(ll, Ah, Bh, Xh);
        Al = ll | 0;
        // v[d] = rotr(v[d] ^ v[a], 32)
        ({ Dh, Dl } = { Dh: Dh ^ Ah, Dl: Dl ^ Al });
        ({ Dh, Dl } = { Dh: rotr32H(Dh, Dl), Dl: rotr32L(Dh) });
        // v[c] = (v[c] + v[d]) | 0;
        ({ h: Ch, l: Cl } = add(Ch, Cl, Dh, Dl));
        // v[b] = rotr(v[b] ^ v[c], 24)
        ({ Bh, Bl } = { Bh: Bh ^ Ch, Bl: Bl ^ Cl });
        ({ Bh, Bl } = { Bh: rotrSH(Bh, Bl, 24), Bl: rotrSL(Bh, Bl, 24) });
        (BUF$1[2 * a] = Al), (BUF$1[2 * a + 1] = Ah);
        (BUF$1[2 * b] = Bl), (BUF$1[2 * b + 1] = Bh);
        (BUF$1[2 * c] = Cl), (BUF$1[2 * c + 1] = Ch);
        (BUF$1[2 * d] = Dl), (BUF$1[2 * d + 1] = Dh);
    }
    function G2$1(a, b, c, d, msg, x) {
        // NOTE: V is LE here
        const Xl = msg[x], Xh = msg[x + 1]; // prettier-ignore
        let Al = BUF$1[2 * a], Ah = BUF$1[2 * a + 1]; // prettier-ignore
        let Bl = BUF$1[2 * b], Bh = BUF$1[2 * b + 1]; // prettier-ignore
        let Cl = BUF$1[2 * c], Ch = BUF$1[2 * c + 1]; // prettier-ignore
        let Dl = BUF$1[2 * d], Dh = BUF$1[2 * d + 1]; // prettier-ignore
        // v[a] = (v[a] + v[b] + x) | 0;
        let ll = add3L(Al, Bl, Xl);
        Ah = add3H(ll, Ah, Bh, Xh);
        Al = ll | 0;
        // v[d] = rotr(v[d] ^ v[a], 16)
        ({ Dh, Dl } = { Dh: Dh ^ Ah, Dl: Dl ^ Al });
        ({ Dh, Dl } = { Dh: rotrSH(Dh, Dl, 16), Dl: rotrSL(Dh, Dl, 16) });
        // v[c] = (v[c] + v[d]) | 0;
        ({ h: Ch, l: Cl } = add(Ch, Cl, Dh, Dl));
        // v[b] = rotr(v[b] ^ v[c], 63)
        ({ Bh, Bl } = { Bh: Bh ^ Ch, Bl: Bl ^ Cl });
        ({ Bh, Bl } = { Bh: rotrBH(Bh, Bl, 63), Bl: rotrBL(Bh, Bl, 63) });
        (BUF$1[2 * a] = Al), (BUF$1[2 * a + 1] = Ah);
        (BUF$1[2 * b] = Bl), (BUF$1[2 * b + 1] = Bh);
        (BUF$1[2 * c] = Cl), (BUF$1[2 * c + 1] = Ch);
        (BUF$1[2 * d] = Dl), (BUF$1[2 * d + 1] = Dh);
    }
    class BLAKE2b extends BLAKE2 {
        constructor(opts = {}) {
            super(128, opts.dkLen === undefined ? 64 : opts.dkLen, opts, 64, 16, 16);
            // Same as SHA-512, but LE
            this.v0l = IV$2[0] | 0;
            this.v0h = IV$2[1] | 0;
            this.v1l = IV$2[2] | 0;
            this.v1h = IV$2[3] | 0;
            this.v2l = IV$2[4] | 0;
            this.v2h = IV$2[5] | 0;
            this.v3l = IV$2[6] | 0;
            this.v3h = IV$2[7] | 0;
            this.v4l = IV$2[8] | 0;
            this.v4h = IV$2[9] | 0;
            this.v5l = IV$2[10] | 0;
            this.v5h = IV$2[11] | 0;
            this.v6l = IV$2[12] | 0;
            this.v6h = IV$2[13] | 0;
            this.v7l = IV$2[14] | 0;
            this.v7h = IV$2[15] | 0;
            const keyLength = opts.key ? opts.key.length : 0;
            this.v0l ^= this.outputLen | (keyLength << 8) | (0x01 << 16) | (0x01 << 24);
            if (opts.salt) {
                const salt = u32(toBytes(opts.salt));
                this.v4l ^= salt[0];
                this.v4h ^= salt[1];
                this.v5l ^= salt[2];
                this.v5h ^= salt[3];
            }
            if (opts.personalization) {
                const pers = u32(toBytes(opts.personalization));
                this.v6l ^= pers[0];
                this.v6h ^= pers[1];
                this.v7l ^= pers[2];
                this.v7h ^= pers[3];
            }
            if (opts.key) {
                // Pad to blockLen and update
                const tmp = new Uint8Array(this.blockLen);
                tmp.set(toBytes(opts.key));
                this.update(tmp);
            }
        }
        // prettier-ignore
        get() {
            let { v0l, v0h, v1l, v1h, v2l, v2h, v3l, v3h, v4l, v4h, v5l, v5h, v6l, v6h, v7l, v7h } = this;
            return [v0l, v0h, v1l, v1h, v2l, v2h, v3l, v3h, v4l, v4h, v5l, v5h, v6l, v6h, v7l, v7h];
        }
        // prettier-ignore
        set(v0l, v0h, v1l, v1h, v2l, v2h, v3l, v3h, v4l, v4h, v5l, v5h, v6l, v6h, v7l, v7h) {
            this.v0l = v0l | 0;
            this.v0h = v0h | 0;
            this.v1l = v1l | 0;
            this.v1h = v1h | 0;
            this.v2l = v2l | 0;
            this.v2h = v2h | 0;
            this.v3l = v3l | 0;
            this.v3h = v3h | 0;
            this.v4l = v4l | 0;
            this.v4h = v4h | 0;
            this.v5l = v5l | 0;
            this.v5h = v5h | 0;
            this.v6l = v6l | 0;
            this.v6h = v6h | 0;
            this.v7l = v7l | 0;
            this.v7h = v7h | 0;
        }
        compress(msg, offset, isLast) {
            this.get().forEach((v, i) => (BUF$1[i] = v)); // First half from state.
            BUF$1.set(IV$2, 16); // Second half from IV.
            let { h, l } = fromBig(BigInt(this.length));
            BUF$1[24] = IV$2[8] ^ l; // Low word of the offset.
            BUF$1[25] = IV$2[9] ^ h; // High word.
            // Invert all bits for last block
            if (isLast) {
                BUF$1[28] = ~BUF$1[28];
                BUF$1[29] = ~BUF$1[29];
            }
            let j = 0;
            const s = SIGMA$1;
            for (let i = 0; i < 12; i++) {
                G1$1(0, 4, 8, 12, msg, offset + 2 * s[j++]);
                G2$1(0, 4, 8, 12, msg, offset + 2 * s[j++]);
                G1$1(1, 5, 9, 13, msg, offset + 2 * s[j++]);
                G2$1(1, 5, 9, 13, msg, offset + 2 * s[j++]);
                G1$1(2, 6, 10, 14, msg, offset + 2 * s[j++]);
                G2$1(2, 6, 10, 14, msg, offset + 2 * s[j++]);
                G1$1(3, 7, 11, 15, msg, offset + 2 * s[j++]);
                G2$1(3, 7, 11, 15, msg, offset + 2 * s[j++]);
                G1$1(0, 5, 10, 15, msg, offset + 2 * s[j++]);
                G2$1(0, 5, 10, 15, msg, offset + 2 * s[j++]);
                G1$1(1, 6, 11, 12, msg, offset + 2 * s[j++]);
                G2$1(1, 6, 11, 12, msg, offset + 2 * s[j++]);
                G1$1(2, 7, 8, 13, msg, offset + 2 * s[j++]);
                G2$1(2, 7, 8, 13, msg, offset + 2 * s[j++]);
                G1$1(3, 4, 9, 14, msg, offset + 2 * s[j++]);
                G2$1(3, 4, 9, 14, msg, offset + 2 * s[j++]);
            }
            this.v0l ^= BUF$1[0] ^ BUF$1[16];
            this.v0h ^= BUF$1[1] ^ BUF$1[17];
            this.v1l ^= BUF$1[2] ^ BUF$1[18];
            this.v1h ^= BUF$1[3] ^ BUF$1[19];
            this.v2l ^= BUF$1[4] ^ BUF$1[20];
            this.v2h ^= BUF$1[5] ^ BUF$1[21];
            this.v3l ^= BUF$1[6] ^ BUF$1[22];
            this.v3h ^= BUF$1[7] ^ BUF$1[23];
            this.v4l ^= BUF$1[8] ^ BUF$1[24];
            this.v4h ^= BUF$1[9] ^ BUF$1[25];
            this.v5l ^= BUF$1[10] ^ BUF$1[26];
            this.v5h ^= BUF$1[11] ^ BUF$1[27];
            this.v6l ^= BUF$1[12] ^ BUF$1[28];
            this.v6h ^= BUF$1[13] ^ BUF$1[29];
            this.v7l ^= BUF$1[14] ^ BUF$1[30];
            this.v7h ^= BUF$1[15] ^ BUF$1[31];
            BUF$1.fill(0);
        }
        destroy() {
            this.destroyed = true;
            this.buffer32.fill(0);
            this.set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        }
    }
    /**
     * BLAKE2b - optimized for 64-bit platforms. JS doesn't have uint64, so it's slower than BLAKE2s.
     * @param msg - message that would be hashed
     * @param opts - dkLen, key, salt, personalization
     */
    const blake2b = wrapConstructorWithOpts((opts) => new BLAKE2b(opts));

    // Initial state:
    // first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19)
    // same as SHA-256
    // prettier-ignore
    const IV$1 = new Uint32Array([
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ]);
    // Mixing function G splitted in two halfs
    function G1(a, b, c, d, x) {
        a = (a + b + x) | 0;
        d = rotr(d ^ a, 16);
        c = (c + d) | 0;
        b = rotr(b ^ c, 12);
        return { a, b, c, d };
    }
    function G2(a, b, c, d, x) {
        a = (a + b + x) | 0;
        d = rotr(d ^ a, 8);
        c = (c + d) | 0;
        b = rotr(b ^ c, 7);
        return { a, b, c, d };
    }
    // prettier-ignore
    function compress(s, offset, msg, rounds, v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15) {
        let j = 0;
        for (let i = 0; i < rounds; i++) {
            ({ a: v0, b: v4, c: v8, d: v12 } = G1(v0, v4, v8, v12, msg[offset + s[j++]]));
            ({ a: v0, b: v4, c: v8, d: v12 } = G2(v0, v4, v8, v12, msg[offset + s[j++]]));
            ({ a: v1, b: v5, c: v9, d: v13 } = G1(v1, v5, v9, v13, msg[offset + s[j++]]));
            ({ a: v1, b: v5, c: v9, d: v13 } = G2(v1, v5, v9, v13, msg[offset + s[j++]]));
            ({ a: v2, b: v6, c: v10, d: v14 } = G1(v2, v6, v10, v14, msg[offset + s[j++]]));
            ({ a: v2, b: v6, c: v10, d: v14 } = G2(v2, v6, v10, v14, msg[offset + s[j++]]));
            ({ a: v3, b: v7, c: v11, d: v15 } = G1(v3, v7, v11, v15, msg[offset + s[j++]]));
            ({ a: v3, b: v7, c: v11, d: v15 } = G2(v3, v7, v11, v15, msg[offset + s[j++]]));
            ({ a: v0, b: v5, c: v10, d: v15 } = G1(v0, v5, v10, v15, msg[offset + s[j++]]));
            ({ a: v0, b: v5, c: v10, d: v15 } = G2(v0, v5, v10, v15, msg[offset + s[j++]]));
            ({ a: v1, b: v6, c: v11, d: v12 } = G1(v1, v6, v11, v12, msg[offset + s[j++]]));
            ({ a: v1, b: v6, c: v11, d: v12 } = G2(v1, v6, v11, v12, msg[offset + s[j++]]));
            ({ a: v2, b: v7, c: v8, d: v13 } = G1(v2, v7, v8, v13, msg[offset + s[j++]]));
            ({ a: v2, b: v7, c: v8, d: v13 } = G2(v2, v7, v8, v13, msg[offset + s[j++]]));
            ({ a: v3, b: v4, c: v9, d: v14 } = G1(v3, v4, v9, v14, msg[offset + s[j++]]));
            ({ a: v3, b: v4, c: v9, d: v14 } = G2(v3, v4, v9, v14, msg[offset + s[j++]]));
        }
        return { v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15 };
    }
    class BLAKE2s extends BLAKE2 {
        constructor(opts = {}) {
            super(64, opts.dkLen === undefined ? 32 : opts.dkLen, opts, 32, 8, 8);
            // Internal state, same as SHA-256
            this.v0 = IV$1[0] | 0;
            this.v1 = IV$1[1] | 0;
            this.v2 = IV$1[2] | 0;
            this.v3 = IV$1[3] | 0;
            this.v4 = IV$1[4] | 0;
            this.v5 = IV$1[5] | 0;
            this.v6 = IV$1[6] | 0;
            this.v7 = IV$1[7] | 0;
            const keyLength = opts.key ? opts.key.length : 0;
            this.v0 ^= this.outputLen | (keyLength << 8) | (0x01 << 16) | (0x01 << 24);
            if (opts.salt) {
                const salt = u32(toBytes(opts.salt));
                this.v4 ^= salt[0];
                this.v5 ^= salt[1];
            }
            if (opts.personalization) {
                const pers = u32(toBytes(opts.personalization));
                this.v6 ^= pers[0];
                this.v7 ^= pers[1];
            }
            if (opts.key) {
                // Pad to blockLen and update
                const tmp = new Uint8Array(this.blockLen);
                tmp.set(toBytes(opts.key));
                this.update(tmp);
            }
        }
        get() {
            const { v0, v1, v2, v3, v4, v5, v6, v7 } = this;
            return [v0, v1, v2, v3, v4, v5, v6, v7];
        }
        // prettier-ignore
        set(v0, v1, v2, v3, v4, v5, v6, v7) {
            this.v0 = v0 | 0;
            this.v1 = v1 | 0;
            this.v2 = v2 | 0;
            this.v3 = v3 | 0;
            this.v4 = v4 | 0;
            this.v5 = v5 | 0;
            this.v6 = v6 | 0;
            this.v7 = v7 | 0;
        }
        compress(msg, offset, isLast) {
            const { h, l } = fromBig(BigInt(this.length));
            // prettier-ignore
            const { v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15 } = compress(SIGMA$1, offset, msg, 10, this.v0, this.v1, this.v2, this.v3, this.v4, this.v5, this.v6, this.v7, IV$1[0], IV$1[1], IV$1[2], IV$1[3], l ^ IV$1[4], h ^ IV$1[5], isLast ? ~IV$1[6] : IV$1[6], IV$1[7]);
            this.v0 ^= v0 ^ v8;
            this.v1 ^= v1 ^ v9;
            this.v2 ^= v2 ^ v10;
            this.v3 ^= v3 ^ v11;
            this.v4 ^= v4 ^ v12;
            this.v5 ^= v5 ^ v13;
            this.v6 ^= v6 ^ v14;
            this.v7 ^= v7 ^ v15;
        }
        destroy() {
            this.destroyed = true;
            this.buffer32.fill(0);
            this.set(0, 0, 0, 0, 0, 0, 0, 0);
        }
    }
    /**
     * BLAKE2s - optimized for 32-bit platforms. JS doesn't have uint64, so it's faster than BLAKE2b.
     * @param msg - message that would be hashed
     * @param opts - dkLen, key, salt, personalization
     */
    const blake2s = wrapConstructorWithOpts((opts) => new BLAKE2s(opts));

    // Flag bitset
    var Flags;
    (function (Flags) {
        Flags[Flags["CHUNK_START"] = 1] = "CHUNK_START";
        Flags[Flags["CHUNK_END"] = 2] = "CHUNK_END";
        Flags[Flags["PARENT"] = 4] = "PARENT";
        Flags[Flags["ROOT"] = 8] = "ROOT";
        Flags[Flags["KEYED_HASH"] = 16] = "KEYED_HASH";
        Flags[Flags["DERIVE_KEY_CONTEXT"] = 32] = "DERIVE_KEY_CONTEXT";
        Flags[Flags["DERIVE_KEY_MATERIAL"] = 64] = "DERIVE_KEY_MATERIAL";
    })(Flags || (Flags = {}));
    const SIGMA = (() => {
        const Id = Array.from({ length: 16 }, (_, i) => i);
        const permute = (arr) => [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8].map((i) => arr[i]);
        const res = [];
        for (let i = 0, v = Id; i < 7; i++, v = permute(v))
            res.push(...v);
        return Uint8Array.from(res);
    })();
    // Why is this so slow? It should be 6x faster than blake2b.
    // - There is only 30% reduction in number of rounds from blake2s
    // - This function uses tree mode to achive parallelisation via SIMD and threading,
    //   however in JS we don't have threads and SIMD, so we get only overhead from tree structure
    // - It is possible to speed it up via Web Workers, hovewer it will make code singnificantly more
    //   complicated, which we are trying to avoid, since this library is intended to be used
    //   for cryptographic purposes. Also, parallelization happens only on chunk level (1024 bytes),
    //   which won't really benefit small inputs.
    class BLAKE3 extends BLAKE2 {
        constructor(opts = {}, flags = 0) {
            super(64, opts.dkLen === undefined ? 32 : opts.dkLen, {}, Number.MAX_SAFE_INTEGER, 0, 0);
            this.flags = 0 | 0;
            this.chunkPos = 0; // Position of current block in chunk
            this.chunksDone = 0; // How many chunks we already have
            this.stack = [];
            // Output
            this.posOut = 0;
            this.bufferOut32 = new Uint32Array(16);
            this.chunkOut = 0; // index of output chunk
            this.enableXOF = true;
            this.outputLen = opts.dkLen === undefined ? 32 : opts.dkLen;
            assertNumber(this.outputLen);
            if (opts.key !== undefined && opts.context !== undefined)
                throw new Error('Blake3: only key or context can be specified at same time');
            else if (opts.key !== undefined) {
                const key = toBytes(opts.key);
                if (key.length !== 32)
                    throw new Error('Blake3: key should be 32 byte');
                this.IV = u32(key);
                this.flags = flags | Flags.KEYED_HASH;
            }
            else if (opts.context !== undefined) {
                const context_key = new BLAKE3({ dkLen: 32 }, Flags.DERIVE_KEY_CONTEXT)
                    .update(opts.context)
                    .digest();
                this.IV = u32(context_key);
                this.flags = flags | Flags.DERIVE_KEY_MATERIAL;
            }
            else {
                this.IV = IV$1.slice();
                this.flags = flags;
            }
            this.state = this.IV.slice();
            this.bufferOut = u8(this.bufferOut32);
        }
        // Unused
        get() {
            return [];
        }
        set() { }
        b2Compress(counter, flags, buf, bufPos = 0) {
            const { state, pos } = this;
            const { h, l } = fromBig(BigInt(counter), true);
            // prettier-ignore
            const { v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15 } = compress(SIGMA, bufPos, buf, 7, state[0], state[1], state[2], state[3], state[4], state[5], state[6], state[7], IV$1[0], IV$1[1], IV$1[2], IV$1[3], h, l, pos, flags);
            state[0] = v0 ^ v8;
            state[1] = v1 ^ v9;
            state[2] = v2 ^ v10;
            state[3] = v3 ^ v11;
            state[4] = v4 ^ v12;
            state[5] = v5 ^ v13;
            state[6] = v6 ^ v14;
            state[7] = v7 ^ v15;
        }
        compress(buf, bufPos = 0, isLast = false) {
            // Compress last block
            let flags = this.flags;
            if (!this.chunkPos)
                flags |= Flags.CHUNK_START;
            if (this.chunkPos === 15 || isLast)
                flags |= Flags.CHUNK_END;
            if (!isLast)
                this.pos = this.blockLen;
            this.b2Compress(this.chunksDone, flags, buf, bufPos);
            this.chunkPos += 1;
            // If current block is last in chunk (16 blocks), then compress chunks
            if (this.chunkPos === 16 || isLast) {
                let chunk = this.state;
                this.state = this.IV.slice();
                // If not the last one, compress only when there are trailing zeros in chunk counter
                // chunks used as binary tree where current stack is path. Zero means current leaf is finished and can be compressed.
                // 1 (001) - leaf not finished (just push current chunk to stack)
                // 2 (010) - leaf finished at depth=1 (merge with last elm on stack and push back)
                // 3 (011) - last leaf not finished
                // 4 (100) - leafs finished at depth=1 and depth=2
                for (let last, chunks = this.chunksDone + 1; isLast || !(chunks & 1); chunks >>= 1) {
                    if (!(last = this.stack.pop()))
                        break;
                    this.buffer32.set(last, 0);
                    this.buffer32.set(chunk, 8);
                    this.pos = this.blockLen;
                    this.b2Compress(0, this.flags | Flags.PARENT, this.buffer32, 0);
                    chunk = this.state;
                    this.state = this.IV.slice();
                }
                this.chunksDone++;
                this.chunkPos = 0;
                this.stack.push(chunk);
            }
            this.pos = 0;
        }
        _cloneInto(to) {
            to = super._cloneInto(to);
            const { IV, flags, state, chunkPos, posOut, chunkOut, stack, chunksDone } = this;
            to.state.set(state.slice());
            to.stack = stack.map((i) => Uint32Array.from(i));
            to.IV.set(IV);
            to.flags = flags;
            to.chunkPos = chunkPos;
            to.chunksDone = chunksDone;
            to.posOut = posOut;
            to.chunkOut = chunkOut;
            to.enableXOF = this.enableXOF;
            to.bufferOut32.set(this.bufferOut32);
            return to;
        }
        destroy() {
            this.destroyed = true;
            this.state.fill(0);
            this.buffer32.fill(0);
            this.IV.fill(0);
            this.bufferOut32.fill(0);
            for (let i of this.stack)
                i.fill(0);
        }
        // Same as b2Compress, but doesn't modify state and returns 16 u32 array (instead of 8)
        b2CompressOut() {
            const { state, pos, flags, buffer32, bufferOut32 } = this;
            const { h, l } = fromBig(BigInt(this.chunkOut++));
            // prettier-ignore
            const { v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15 } = compress(SIGMA, 0, buffer32, 7, state[0], state[1], state[2], state[3], state[4], state[5], state[6], state[7], IV$1[0], IV$1[1], IV$1[2], IV$1[3], l, h, pos, flags);
            bufferOut32[0] = v0 ^ v8;
            bufferOut32[1] = v1 ^ v9;
            bufferOut32[2] = v2 ^ v10;
            bufferOut32[3] = v3 ^ v11;
            bufferOut32[4] = v4 ^ v12;
            bufferOut32[5] = v5 ^ v13;
            bufferOut32[6] = v6 ^ v14;
            bufferOut32[7] = v7 ^ v15;
            bufferOut32[8] = state[0] ^ v8;
            bufferOut32[9] = state[1] ^ v9;
            bufferOut32[10] = state[2] ^ v10;
            bufferOut32[11] = state[3] ^ v11;
            bufferOut32[12] = state[4] ^ v12;
            bufferOut32[13] = state[5] ^ v13;
            bufferOut32[14] = state[6] ^ v14;
            bufferOut32[15] = state[7] ^ v15;
            this.posOut = 0;
        }
        finish() {
            if (this.finished)
                return;
            this.finished = true;
            // Padding
            this.buffer.fill(0, this.pos);
            // Process last chunk
            let flags = this.flags | Flags.ROOT;
            if (this.stack.length) {
                flags |= Flags.PARENT;
                this.compress(this.buffer32, 0, true);
                this.chunksDone = 0;
                this.pos = this.blockLen;
            }
            else {
                flags |= (!this.chunkPos ? Flags.CHUNK_START : 0) | Flags.CHUNK_END;
            }
            this.flags = flags;
            this.b2CompressOut();
        }
        writeInto(out) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            if (!(out instanceof Uint8Array))
                throw new Error('Blake3: Invalid output buffer');
            this.finish();
            const { blockLen, bufferOut } = this;
            for (let pos = 0, len = out.length; pos < len;) {
                if (this.posOut >= blockLen)
                    this.b2CompressOut();
                const take = Math.min(this.blockLen - this.posOut, len - pos);
                out.set(bufferOut.subarray(this.posOut, this.posOut + take), pos);
                this.posOut += take;
                pos += take;
            }
            return out;
        }
        xofInto(out) {
            if (!this.enableXOF)
                throw new Error('XOF impossible after digest call');
            return this.writeInto(out);
        }
        xof(bytes) {
            assertNumber(bytes);
            return this.xofInto(new Uint8Array(bytes));
        }
        digestInto(out) {
            if (out.length < this.outputLen)
                throw new Error('Blake3: Invalid output buffer');
            if (this.finished)
                throw new Error('digest() was already called');
            this.enableXOF = false;
            this.writeInto(out);
            this.destroy();
            return out;
        }
        digest() {
            return this.digestInto(new Uint8Array(this.outputLen));
        }
    }
    /**
     * BLAKE3 hash function.
     * @param msg - message that would be hashed
     * @param opts - dkLen, key, context
     */
    const blake3 = wrapConstructorWithOpts((opts) => new BLAKE3(opts));

    // HMAC (RFC 2104)
    class HMAC extends Hash {
        constructor(hash, _key) {
            super();
            this.finished = false;
            this.destroyed = false;
            assertHash(hash);
            const key = toBytes(_key);
            this.iHash = hash.create();
            if (!(this.iHash instanceof Hash))
                throw new TypeError('Expected instance of class which extends utils.Hash');
            const blockLen = (this.blockLen = this.iHash.blockLen);
            this.outputLen = this.iHash.outputLen;
            const pad = new Uint8Array(blockLen);
            // blockLen can be bigger than outputLen
            pad.set(key.length > this.iHash.blockLen ? hash.create().update(key).digest() : key);
            for (let i = 0; i < pad.length; i++)
                pad[i] ^= 0x36;
            this.iHash.update(pad);
            // By doing update (processing of first block) of outer hash here we can re-use it between multiple calls via clone
            this.oHash = hash.create();
            // Undo internal XOR && apply outer XOR
            for (let i = 0; i < pad.length; i++)
                pad[i] ^= 0x36 ^ 0x5c;
            this.oHash.update(pad);
            pad.fill(0);
        }
        update(buf) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            this.iHash.update(buf);
            return this;
        }
        digestInto(out) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            if (!(out instanceof Uint8Array) || out.length !== this.outputLen)
                throw new Error('HMAC: Invalid output buffer');
            if (this.finished)
                throw new Error('digest() was already called');
            this.finished = true;
            this.iHash.digestInto(out);
            this.oHash.update(out);
            this.oHash.digestInto(out);
            this.destroy();
        }
        digest() {
            const out = new Uint8Array(this.oHash.outputLen);
            this.digestInto(out);
            return out;
        }
        _cloneInto(to) {
            // Create new instance without calling constructor since key already in state and we don't know it.
            to || (to = Object.create(Object.getPrototypeOf(this), {}));
            const { oHash, iHash, finished, destroyed, blockLen, outputLen } = this;
            to = to;
            to.finished = finished;
            to.destroyed = destroyed;
            to.blockLen = blockLen;
            to.outputLen = outputLen;
            to.oHash = oHash._cloneInto(to.oHash);
            to.iHash = iHash._cloneInto(to.iHash);
            return to;
        }
        destroy() {
            this.destroyed = true;
            this.oHash.destroy();
            this.iHash.destroy();
        }
    }
    /**
     * HMAC: RFC2104 message authentication code.
     * @param hash - function that would be used e.g. sha256
     * @param key - message key
     * @param message - message data
     */
    const hmac = (hash, key, message) => new HMAC(hash, key).update(message).digest();
    hmac.create = (hash, key) => new HMAC(hash, key);

    // HKDF (RFC 5869)
    // https://soatok.blog/2021/11/17/understanding-hkdf/
    /**
     * HKDF-Extract(IKM, salt) -> PRK
     * Arguments position differs from spec (IKM is first one, since it is not optional)
     * @param hash
     * @param ikm
     * @param salt
     * @returns
     */
    function extract(hash, ikm, salt) {
        assertHash(hash);
        // NOTE: some libraries treat zero-length array as 'not provided';
        // we don't, since we have undefined as 'not provided'
        // https://github.com/RustCrypto/KDFs/issues/15
        if (salt === undefined)
            salt = new Uint8Array(hash.outputLen); // if not provided, it is set to a string of HashLen zeros
        return hmac(hash, toBytes(salt), toBytes(ikm));
    }
    // HKDF-Expand(PRK, info, L) -> OKM
    const HKDF_COUNTER = new Uint8Array([0]);
    const EMPTY_BUFFER = new Uint8Array();
    /**
     * HKDF-expand from the spec.
     * @param prk - a pseudorandom key of at least HashLen octets (usually, the output from the extract step)
     * @param info - optional context and application specific information (can be a zero-length string)
     * @param length - length of output keying material in octets
     */
    function expand(hash, prk, info, length = 32) {
        assertHash(hash);
        assertNumber(length);
        if (length > 255 * hash.outputLen)
            throw new Error('Length should be <= 255*HashLen');
        const blocks = Math.ceil(length / hash.outputLen);
        if (info === undefined)
            info = EMPTY_BUFFER;
        // first L(ength) octets of T
        const okm = new Uint8Array(blocks * hash.outputLen);
        // Re-use HMAC instance between blocks
        const HMAC = hmac.create(hash, prk);
        const HMACTmp = HMAC._cloneInto();
        const T = new Uint8Array(HMAC.outputLen);
        for (let counter = 0; counter < blocks; counter++) {
            HKDF_COUNTER[0] = counter + 1;
            // T(0) = empty string (zero length)
            // T(N) = HMAC-Hash(PRK, T(N-1) | info | N)
            HMACTmp.update(counter === 0 ? EMPTY_BUFFER : T)
                .update(info)
                .update(HKDF_COUNTER)
                .digestInto(T);
            okm.set(T, hash.outputLen * counter);
            HMAC._cloneInto(HMACTmp);
        }
        HMAC.destroy();
        HMACTmp.destroy();
        T.fill(0);
        HKDF_COUNTER.fill(0);
        return okm.slice(0, length);
    }
    /**
     * HKDF (RFC 5869): extract + expand in one step.
     * @param hash - hash function that would be used (e.g. sha256)
     * @param ikm - input keying material, the initial key
     * @param salt - optional salt value (a non-secret random value)
     * @param info - optional context and application specific information
     * @param length - length of output keying material in octets
     */
    const hkdf = (hash, ikm, salt, info, length) => expand(hash, extract(hash, ikm, salt), info, length);

    // Common prologue and epilogue for sync/async functions
    function pbkdf2Init(hash, _password, _salt, _opts) {
        assertHash(hash);
        const opts = checkOpts({ dkLen: 32, asyncTick: 10 }, _opts);
        const { c, dkLen, asyncTick } = opts;
        assertNumber(c);
        assertNumber(dkLen);
        assertNumber(asyncTick);
        if (c < 1)
            throw new Error('PBKDF2: iterations (c) should be >= 1');
        const password = toBytes(_password);
        const salt = toBytes(_salt);
        // DK = PBKDF2(PRF, Password, Salt, c, dkLen);
        const DK = new Uint8Array(dkLen);
        // U1 = PRF(Password, Salt + INT_32_BE(i))
        const PRF = hmac.create(hash, password);
        const PRFSalt = PRF._cloneInto().update(salt);
        return { c, dkLen, asyncTick, DK, PRF, PRFSalt };
    }
    function pbkdf2Output(PRF, PRFSalt, DK, prfW, u) {
        PRF.destroy();
        PRFSalt.destroy();
        if (prfW)
            prfW.destroy();
        u.fill(0);
        return DK;
    }
    /**
     * PBKDF2-HMAC: RFC 2898 key derivation function
     * @param hash - hash function that would be used e.g. sha256
     * @param password - password from which a derived key is generated
     * @param salt - cryptographic salt
     * @param opts - {c, dkLen} where c is work factor and dkLen is output message size
     */
    function pbkdf2$1(hash, password, salt, opts) {
        const { c, dkLen, DK, PRF, PRFSalt } = pbkdf2Init(hash, password, salt, opts);
        let prfW; // Working copy
        const arr = new Uint8Array(4);
        const view = createView(arr);
        const u = new Uint8Array(PRF.outputLen);
        // DK = T1 + T2 + ⋯ + Tdklen/hlen
        for (let ti = 1, pos = 0; pos < dkLen; ti++, pos += PRF.outputLen) {
            // Ti = F(Password, Salt, c, i)
            const Ti = DK.subarray(pos, pos + PRF.outputLen);
            view.setInt32(0, ti, false);
            // F(Password, Salt, c, i) = U1 ^ U2 ^ ⋯ ^ Uc
            // U1 = PRF(Password, Salt + INT_32_BE(i))
            (prfW = PRFSalt._cloneInto(prfW)).update(arr).digestInto(u);
            Ti.set(u.subarray(0, Ti.length));
            for (let ui = 1; ui < c; ui++) {
                // Uc = PRF(Password, Uc−1)
                PRF._cloneInto(prfW).update(u).digestInto(u);
                for (let i = 0; i < Ti.length; i++)
                    Ti[i] ^= u[i];
            }
        }
        return pbkdf2Output(PRF, PRFSalt, DK, prfW, u);
    }
    async function pbkdf2Async(hash, password, salt, opts) {
        const { c, dkLen, asyncTick, DK, PRF, PRFSalt } = pbkdf2Init(hash, password, salt, opts);
        let prfW; // Working copy
        const arr = new Uint8Array(4);
        const view = createView(arr);
        const u = new Uint8Array(PRF.outputLen);
        // DK = T1 + T2 + ⋯ + Tdklen/hlen
        for (let ti = 1, pos = 0; pos < dkLen; ti++, pos += PRF.outputLen) {
            // Ti = F(Password, Salt, c, i)
            const Ti = DK.subarray(pos, pos + PRF.outputLen);
            view.setInt32(0, ti, false);
            // F(Password, Salt, c, i) = U1 ^ U2 ^ ⋯ ^ Uc
            // U1 = PRF(Password, Salt + INT_32_BE(i))
            (prfW = PRFSalt._cloneInto(prfW)).update(arr).digestInto(u);
            Ti.set(u.subarray(0, Ti.length));
            await asyncLoop(c - 1, asyncTick, (i) => {
                // Uc = PRF(Password, Uc−1)
                PRF._cloneInto(prfW).update(u).digestInto(u);
                for (let i = 0; i < Ti.length; i++)
                    Ti[i] ^= u[i];
            });
        }
        return pbkdf2Output(PRF, PRFSalt, DK, prfW, u);
    }
////////////////////////////////



    // Polyfill for Safari 14
    function setBigUint64(view, byteOffset, value, isLE) {
        if (typeof view.setBigUint64 === 'function')
            return view.setBigUint64(byteOffset, value, isLE);
        const _32n = BigInt(32);
        const _u32_max = BigInt(0xffffffff);
        const wh = Number((value >> _32n) & _u32_max);
        const wl = Number(value & _u32_max);
        const h = isLE ? 4 : 0;
        const l = isLE ? 0 : 4;
        view.setUint32(byteOffset + h, wh, isLE);
        view.setUint32(byteOffset + l, wl, isLE);
    }
    // Base SHA2 class (RFC 6234)
    class SHA2 extends Hash {
        constructor(blockLen, outputLen, padOffset, isLE) {
            super();
            this.blockLen = blockLen;
            this.outputLen = outputLen;
            this.padOffset = padOffset;
            this.isLE = isLE;
            this.finished = false;
            this.length = 0;
            this.pos = 0;
            this.destroyed = false;
            this.buffer = new Uint8Array(blockLen);
            this.view = createView(this.buffer);
        }
        update(data) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            const { view, buffer, blockLen, finished } = this;
            if (finished)
                throw new Error('digest() was already called');
            data = toBytes(data);
            const len = data.length;
            for (let pos = 0; pos < len;) {
                const take = Math.min(blockLen - this.pos, len - pos);
                // Fast path: we have at least one block in input, cast it to view and process
                if (take === blockLen) {
                    const dataView = createView(data);
                    for (; blockLen <= len - pos; pos += blockLen)
                        this.process(dataView, pos);
                    continue;
                }
                buffer.set(data.subarray(pos, pos + take), this.pos);
                this.pos += take;
                pos += take;
                if (this.pos === blockLen) {
                    this.process(view, 0);
                    this.pos = 0;
                }
            }
            this.length += data.length;
            this.roundClean();
            return this;
        }
        digestInto(out) {
            if (this.destroyed)
                throw new Error('instance is destroyed');
            if (!(out instanceof Uint8Array) || out.length < this.outputLen)
                throw new Error('_Sha2: Invalid output buffer');
            if (this.finished)
                throw new Error('digest() was already called');
            this.finished = true;
            // Padding
            // We can avoid allocation of buffer for padding completely if it
            // was previously not allocated here. But it won't change performance.
            const { buffer, view, blockLen, isLE } = this;
            let { pos } = this;
            // append the bit '1' to the message
            buffer[pos++] = 0b10000000;
            this.buffer.subarray(pos).fill(0);
            // we have less than padOffset left in buffer, so we cannot put length in current block, need process it and pad again
            if (this.padOffset > blockLen - pos) {
                this.process(view, 0);
                pos = 0;
            }
            // Pad until full block byte with zeros
            for (let i = pos; i < blockLen; i++)
                buffer[i] = 0;
            // NOTE: sha512 requires length to be 128bit integer, but length in JS will overflow before that
            // You need to write around 2 exabytes (u64_max / 8 / (1024**6)) for this to happen.
            // So we just write lowest 64bit of that value.
            setBigUint64(view, blockLen - 8, BigInt(this.length * 8), isLE);
            this.process(view, 0);
            const oview = createView(out);
            this.get().forEach((v, i) => oview.setUint32(4 * i, v, isLE));
        }
        digest() {
            const { buffer, outputLen } = this;
            this.digestInto(buffer);
            const res = buffer.slice(0, outputLen);
            this.destroy();
            return res;
        }
        _cloneInto(to) {
            to || (to = new this.constructor());
            to.set(...this.get());
            const { blockLen, buffer, length, finished, destroyed, pos } = this;
            to.length = length;
            to.pos = pos;
            to.finished = finished;
            to.destroyed = destroyed;
            if (length % blockLen)
                to.buffer.set(buffer);
            return to;
        }
    }

    // https://homes.esat.kuleuven.be/~bosselae/ripemd160.html
    // https://homes.esat.kuleuven.be/~bosselae/ripemd160/pdf/AB-9601/AB-9601.pdf
    const Rho = new Uint8Array([7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8]);
    const Id = Uint8Array.from({ length: 16 }, (_, i) => i);
    const Pi = Id.map((i) => (9 * i + 5) % 16);
    let idxL = [Id];
    let idxR = [Pi];
    for (let i = 0; i < 4; i++)
        for (let j of [idxL, idxR])
            j.push(j[i].map((k) => Rho[k]));
    const shifts = [
        [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8],
        [12, 13, 11, 15, 6, 9, 9, 7, 12, 15, 11, 13, 7, 8, 7, 7],
        [13, 15, 14, 11, 7, 7, 6, 8, 13, 14, 13, 12, 5, 5, 6, 9],
        [14, 11, 12, 14, 8, 6, 5, 5, 15, 12, 15, 14, 9, 9, 8, 6],
        [15, 12, 13, 13, 9, 5, 8, 6, 14, 11, 12, 11, 8, 6, 5, 5],
    ].map((i) => new Uint8Array(i));
    const shiftsL = idxL.map((idx, i) => idx.map((j) => shifts[i][j]));
    const shiftsR = idxR.map((idx, i) => idx.map((j) => shifts[i][j]));
    const Kl = new Uint32Array([0x00000000, 0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xa953fd4e]);
    const Kr = new Uint32Array([0x50a28be6, 0x5c4dd124, 0x6d703ef3, 0x7a6d76e9, 0x00000000]);
    // The rotate left (circular left shift) operation for uint32
    const rotl$1 = (word, shift) => (word << shift) | (word >>> (32 - shift));
    // It's called f() in spec.
    function f(group, x, y, z) {
        if (group === 0)
            return x ^ y ^ z;
        else if (group === 1)
            return (x & y) | (~x & z);
        else if (group === 2)
            return (x | ~y) ^ z;
        else if (group === 3)
            return (x & z) | (y & ~z);
        else
            return x ^ (y | ~z);
    }
    // Temporary buffer, not used to store anything between runs
    const BUF = new Uint32Array(16);
    class RIPEMD160 extends SHA2 {
        constructor() {
            super(64, 20, 8, true);
            this.h0 = 0x67452301 | 0;
            this.h1 = 0xefcdab89 | 0;
            this.h2 = 0x98badcfe | 0;
            this.h3 = 0x10325476 | 0;
            this.h4 = 0xc3d2e1f0 | 0;
        }
        get() {
            const { h0, h1, h2, h3, h4 } = this;
            return [h0, h1, h2, h3, h4];
        }
        set(h0, h1, h2, h3, h4) {
            this.h0 = h0 | 0;
            this.h1 = h1 | 0;
            this.h2 = h2 | 0;
            this.h3 = h3 | 0;
            this.h4 = h4 | 0;
        }
        process(view, offset) {
            for (let i = 0; i < 16; i++, offset += 4)
                BUF[i] = view.getUint32(offset, true);
            // prettier-ignore
            let al = this.h0 | 0, ar = al, bl = this.h1 | 0, br = bl, cl = this.h2 | 0, cr = cl, dl = this.h3 | 0, dr = dl, el = this.h4 | 0, er = el;
            // Instead of iterating 0 to 80, we split it into 5 groups
            // And use the groups in constants, functions, etc. Much simpler
            for (let group = 0; group < 5; group++) {
                const rGroup = 4 - group;
                const hbl = Kl[group], hbr = Kr[group]; // prettier-ignore
                const rl = idxL[group], rr = idxR[group]; // prettier-ignore
                const sl = shiftsL[group], sr = shiftsR[group]; // prettier-ignore
                for (let i = 0; i < 16; i++) {
                    const tl = (rotl$1(al + f(group, bl, cl, dl) + BUF[rl[i]] + hbl, sl[i]) + el) | 0;
                    al = el, el = dl, dl = rotl$1(cl, 10) | 0, cl = bl, bl = tl; // prettier-ignore
                }
                // 2 loops are 10% faster
                for (let i = 0; i < 16; i++) {
                    const tr = (rotl$1(ar + f(rGroup, br, cr, dr) + BUF[rr[i]] + hbr, sr[i]) + er) | 0;
                    ar = er, er = dr, dr = rotl$1(cr, 10) | 0, cr = br, br = tr; // prettier-ignore
                }
            }
            // Add the compressed chunk to the current hash value
            this.set((this.h1 + cl + dr) | 0, (this.h2 + dl + er) | 0, (this.h3 + el + ar) | 0, (this.h4 + al + br) | 0, (this.h0 + bl + cr) | 0);
        }
        roundClean() {
            BUF.fill(0);
        }
        destroy() {
            this.destroyed = true;
            this.buffer.fill(0);
            this.set(0, 0, 0, 0, 0);
        }
    }
    /**
     * RIPEMD-160 - a hash function from 1990s.
     * @param message - msg that would be hashed
     */
    const ripemd160 = wrapConstructor(() => new RIPEMD160());

    exports.ripemd160 = ripemd160;
    Object.defineProperty(exports, '__esModule', { value: true });

}));
