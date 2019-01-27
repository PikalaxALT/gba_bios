#include <stdbool.h>
#include "global.h"
#include "huff.h"

static int cmp_tree(const void * a0, const void * b0) {
    return ((struct HuffData *)b0)->value - ((struct HuffData *)a0)->value;
}

static int write_tree(unsigned char * dest, struct HuffBranch * tree, struct BitEncoding * encoding, int offset, int skip, uint32_t curBitstream, int depth) {
    skip &= ~1;
    int outSize = 0;
    depth++;

    uint32_t curLeftEncoding = curBitstream << 1;
    uint32_t curRightEncoding = curLeftEncoding | 1;

    dest[offset] = (skip / 2 - 1) & 0x3F;
    if (tree->left->header.isLeaf) {
        dest[offset] |= 0x80;
        dest[offset + skip] = tree->left->leaf.key;
        encoding[tree->left->leaf.key].nbits = depth;
        encoding[tree->left->leaf.key].bitstring = curLeftEncoding;
    } else {
        outSize = write_tree(dest, &tree->left->branch, encoding, offset + skip, 0, curLeftEncoding, depth);
    }
    if (tree->right->header.isLeaf) {
        dest[offset] |= 0x40;
        dest[offset + skip + 1] = tree->right->leaf.key;
        encoding[tree->right->leaf.key].nbits = depth;
        encoding[tree->right->leaf.key].bitstring = curRightEncoding;
    } else {
        outSize += write_tree(dest, &tree->right->branch, encoding, offset + skip + 1, outSize, curRightEncoding, depth);
    }

    return outSize + 2;
}

static void write_bits(unsigned char * dest, int * destPos, struct BitEncoding * encoding, int value, uint32_t * buff, int * buffBits) {
    int nbits = encoding[value].nbits;
    uint32_t bitstring = encoding[value].bitstring;

    if (*buffBits + nbits >= 32) {
        int diff = *buffBits + nbits - 32;
        *buff <<= nbits - diff;
        *buff |= bitstring >> diff;
        bitstring &= ~(1 << diff);
        nbits = diff;
        *(uint32_t *)(dest + *destPos) = *buff;
        *buff = 0;
        *destPos += 4;
    }
    *buff <<= nbits;
    *buff |= bitstring;
}

unsigned char * HuffCompress(unsigned char * src, int srcSize, int * compressedSize_p, int bitDepth) {
    if (srcSize <= 0)
        goto fail;

    unsigned char *dest = malloc(srcSize);
    if (dest == NULL)
        goto fail;

    int nitems = 1 << bitDepth;
    HuffNode_t * tree = calloc(nitems * 2 - 1, sizeof(HuffNode_t));
    if (tree == NULL)
        goto fail;

    struct BitEncoding * encoding = calloc(nitems, sizeof(struct BitEncoding));
    if (encoding == NULL)
        goto fail;

    for (int i = 0; i < nitems; i++) {
        tree[i].header.isLeaf = 1;
        tree[i].header.value = 0;
        tree[i].leaf.key = i;
    }

    for (int i = 0; i < srcSize; i++) {
        tree[src[i]].header.value++;
    }

    qsort(tree, nitems, sizeof(HuffNode_t), cmp_tree);

    while (tree[nitems - 1].header.value == 0)
        nitems--;

    HuffNode_t * root = tree + nitems;
    HuffNode_t * remnants = tree;
    HuffNode_t * endptr = root;

    for (int i = 0; i < nitems; i++) {
        HuffNode_t * left = remnants;
        HuffNode_t * right = remnants + 1;
        remnants += 2;
        if (left->header.value < right->header.value) {
            left++;
            right--;
        }
        endptr->header.isLeaf = 0;
        endptr->header.value = left->header.value + right->header.value;
        endptr->branch.left = left;
        endptr->branch.right = right;
        endptr++;
        qsort(remnants, nitems - i - 1, sizeof(HuffNode_t), cmp_tree);
    }

    int treeSize = write_tree(dest, &remnants->branch, encoding, 5, 0, 0, 0);
    free(tree);

    int destPos = 4 + treeSize;
    uint32_t destBuf = 0;
    int destBitPos = 0;

    for (int srcPos = 0; srcPos < srcSize; srcPos++) {
        if (bitDepth == 8) {
            write_bits(dest, &destPos, encoding, src[srcPos], &destBuf, &destBitPos);
        }
        else {
            write_bits(dest, &destPos, encoding, src[srcPos] >> 4, &destBuf, &destBitPos);
            write_bits(dest, &destPos, encoding, src[srcPos] & 0xF, &destBuf, &destBitPos);
        }
    }

    free(encoding);

    dest[0] = bitDepth;
    dest[1] = srcSize;
    dest[2] = srcSize >> 8;
    dest[3] = srcSize >> 16;
    dest[4] = treeSize / 2 - 1;
    *compressedSize_p = (destPos + 3) & ~3;
    return dest;

fail:
    FATAL_ERROR("Fatal error while decompressing Huff file.\n");
}

unsigned char * HuffDecompress(unsigned char * src, int srcSize, int * uncompressedSize_p) {
    if (srcSize < 4)
        goto fail;

    int bitDepth = *src & 15;
    if (bitDepth != 4 && bitDepth != 8)
        goto fail;

    int destSize = (src[3] << 16) | (src[2] << 8) | src[1];

    unsigned char *dest = malloc(destSize);

    if (dest == NULL)
        goto fail;

    int treePos = 5;
    int treeSize = (src[4] + 1) * 2;
    int srcPos = 4 + treeSize;
    int destPos = 0;
    int curValPos = 0;
    uint32_t destTmp = 0;

    for (;;)
    {
        if (srcPos >= srcSize)
            goto fail;
        uint32_t window = *(uint32_t *)(src + srcPos);
        srcPos += 4;
        for (int i = 0; i < 32; i++) {
            bool curBit = (window >> 31) != 0;
            unsigned char treeView = src[treePos];
            bool isLeaf = ((treeView << curBit) & 0x80) != 0;
            treePos &= ~1; // align
            treePos += ((treeView & 0x3F) + 1) * 2 + curBit;
            if (isLeaf) {
                destTmp <<= bitDepth;
                destTmp |= src[treePos];
                curValPos++;
                if (curValPos == 32 / bitDepth) {
                    *(uint32_t *)(dest + destPos) = destTmp;
                    destPos += 4;
                    if (destPos == destSize) {
                        *uncompressedSize_p = destSize;
                        return dest;
                    }
                    destTmp = 0;
                    curValPos = 0;
                }
                treePos = 5;
            }
            window <<= 1;
        }
    }

fail:
    FATAL_ERROR("Fatal error while decompressing Huff file.\n");
}
