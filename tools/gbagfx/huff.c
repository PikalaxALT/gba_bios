#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include "global.h"
#include "huff.h"

static int cmp_tree(const void * a0, const void * b0) {
    return ((struct HuffData *)a0)->value - ((struct HuffData *)b0)->value;
}

int msort(void * data, size_t count, size_t size, int (*cmp)(const void *, const void *)) {
    void * buffer;
    void * leftPtr;
    void * rightPtr;
    int i;

    switch (count) {
        case 0:
        case 1:
            return 1;
        case 2:
            if (cmp(data, data + size) > 0) {
                buffer = malloc(size);
                if (buffer == NULL)
                    return 0;
                memcpy(buffer, data, size);
                memcpy(data, data + size, size);
                memcpy(data + size, buffer, size);
                free(buffer);
            }
            break;
        default:
            buffer = calloc(count, size);
            if (buffer == NULL)
                return 0;
            memcpy(buffer, data, count * size);
            leftPtr = buffer;
            rightPtr = buffer + count / 2 * size;
            if (!msort(leftPtr, count / 2, size, cmp))
                return 0;
            if (!msort(rightPtr, count / 2 + (count & 1), size, cmp))
                return 0;
            for (i = 0; i < count; i++) {
                if (cmp(leftPtr, rightPtr) <= 0) {
                    memcpy(data + i * size, leftPtr, size);
                    leftPtr += size;
                    if (leftPtr == buffer + count / 2 * size) break;
                } else {
                    memcpy(data + i * size, rightPtr, size);
                    rightPtr += size;
                    if (rightPtr == buffer + count * size) break;
                }
            }
            if (++i < count) {
                if (leftPtr < buffer + count / 2 * size) {
                    memcpy(data + i * size, leftPtr, buffer + count / 2 * size - leftPtr);
                }
                else {
                    memcpy(data + i * size, rightPtr, buffer + count * size - rightPtr);
                }
            }
            free(buffer);
            break;
    }

    return 1;
}

static inline void dump_bits(unsigned char * dest, int * destPos, uint32_t * buff) {
    dest[*destPos] = *buff;
    dest[*destPos + 1] = *buff >> 8;
    dest[*destPos + 2] = *buff >> 16;
    dest[*destPos + 3] = *buff >> 24;
    *buff = 0;
    *destPos += 4;
}

void create_bit_encoding(struct HuffBranch * tree, struct BitEncoding * encoding, uint32_t curBitstream, int depth) {

    HuffNode_t * left = tree->left;
    HuffNode_t * right = tree->right;

    depth++;
    uint32_t curLeftEncoding = curBitstream << 1;
    uint32_t curRightEncoding = curLeftEncoding | 1;

    for (int i = 0; i < depth - 1; i++) {
        fputc('\t', stderr);
    }
    if (left->header.isLeaf) {
        encoding[left->leaf.key].nbits = depth;
        encoding[left->leaf.key].bitstring = curLeftEncoding;
    } else {
        create_bit_encoding(&left->branch, encoding, curLeftEncoding, depth);
    }

    for (int i = 0; i < depth - 1; i++) {
        fputc('\t', stderr);
    }
    if (right->header.isLeaf) {
        encoding[right->leaf.key].nbits = depth;
        encoding[right->leaf.key].bitstring = curRightEncoding;
    } else {
        create_bit_encoding(&right->branch, encoding, curRightEncoding, depth);
    }
}

static void write_tree(unsigned char * dest, HuffNode_t * tree, int nitems) {
    HuffNode_t * traversal = calloc(2 * nitems - 1, sizeof(HuffNode_t));
    int i, j, k;
    i = 1;
    bool isTerminal = false;
    for (int i = 0; i < 2 * nitems - 1; i++) {
        traversal[i].header.value = 0x7FFF;
    }
    traversal[0] = *tree;
    for (int depth = 1; depth < 8 && !isTerminal; depth++) {
        isTerminal = true;
        for (j = 0; j < 1 << depth; j++) {
            HuffNode_t * currNode = traversal;
            HuffNode_t * parent = NULL;
            for (k = 0; k < depth; k++) {
                if (currNode->header.isLeaf)
                    break;
                parent = currNode;
                if ((j >> (depth - k - 1)) & 1)
                    currNode = currNode->branch.right;
                else
                    currNode = currNode->branch.left;
            }
            if (k == depth) {
                if (!currNode->header.isLeaf)
                    isTerminal = false;
                bool rightFork = (j & 1) == 1;
                traversal[i] = *currNode;
                traversal[i].header.isRightFork = rightFork;
                int right_i = parent - traversal;
                if (parent != NULL) {
                    if (depth > 1)
                        assert(right_i > 0);
                    traversal[i].header.value = right_i;
                    if (rightFork)
                        parent->branch.right = traversal + i;
                    else
                        parent->branch.left = traversal + i;
                } else {
                    traversal[i].header.value = -1u;
                }
                i++;
            }
        }
    }

    traversal[0].header.value = -1;
    traversal[0].header.isRightFork = true;
    dest[4] = nitems - 1;

    for (i = 0; i < 2 * nitems - 1; i++) {
        if (traversal[i].header.value == 0x7FFF)
            break;
        if (traversal[i].header.isLeaf) {
            dest[5 + i] = traversal[i].leaf.key;
        } else {
            int right_i = traversal[i].branch.right - traversal;
            dest[5 + i] = (((right_i - i) / 2) - 1) & 0x3F;
            dest[5 + i] |= (0x80 * traversal[i].branch.left->header.isLeaf);
            dest[5 + i] |= (0x40 * traversal[i].branch.right->header.isLeaf);
        }
    }

    free(traversal);
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
        dump_bits(dest, destPos, buff);
        *buffBits = 0;
    }
    if (nbits != 0) {
        *buff <<= nbits;
        *buff |= bitstring;
        *buffBits += nbits;
    }
}

unsigned char * HuffCompress(unsigned char * src, int srcSize, int * compressedSize_p, int bitDepth) {
    if (srcSize <= 0)
        goto fail;

    int worstCaseDestSize = 4 + (1 << bitDepth) + srcSize;

    unsigned char *dest = malloc(worstCaseDestSize);
    if (dest == NULL)
        goto fail;

    int nitems = 1 << bitDepth;

    HuffNode_t * freqs = calloc(nitems, sizeof(HuffNode_t));
    if (freqs == NULL)
        goto fail;

    struct BitEncoding * encoding = calloc(nitems, sizeof(struct BitEncoding));
    if (encoding == NULL)
        goto fail;

    for (int i = 0; i < nitems; i++) {
        freqs[i].header.isLeaf = 1;
        freqs[i].header.value = 0;
        freqs[i].leaf.key = i;
    }

    for (int i = 0; i < srcSize; i++) {
        if (bitDepth == 8) {
            freqs[src[i]].header.value++;
        } else {
            freqs[src[i] >> 4].header.value++;
            freqs[src[i] & 0xF].header.value++;
        }
    }

    if (!msort(freqs, nitems, sizeof(HuffNode_t), cmp_tree))
        goto fail;

    for (int i = 0; i < nitems; i++) {
        if (freqs[i].header.value != 0) {
            if (i > 0) {
                for (int j = i; j < nitems; j++) {
                    freqs[j - i] = freqs[j];
                }
                nitems -= i;
            }
            break;
        }
        if (i == nitems - 1)
            goto fail;
    }

    HuffNode_t * tree = calloc(nitems * 2 - 1, sizeof(HuffNode_t));
    if (tree == NULL)
        goto fail;

    HuffNode_t * endptr = freqs + nitems - 2;

    for (int i = 0; i < nitems - 1; i++) {
        HuffNode_t * left = freqs;
        HuffNode_t * right = freqs + 1;
        tree[i * 2] = *right;
        tree[i * 2 + 1] = *left;
        for (int j = 0; j < nitems - i - 2; j++)
            freqs[j] = freqs[j + 2];
        endptr->header.isLeaf = 0;
        endptr->header.value = tree[i * 2].header.value + tree[i * 2 + 1].header.value;
        endptr->branch.left = tree + i * 2;
        endptr->branch.right = tree + i * 2 + 1;
        endptr--;
        if (i == nitems - 2)
            break;
        if (!msort(freqs, nitems - i - 1, sizeof(HuffNode_t), cmp_tree))
            goto fail;
    }

    create_bit_encoding(&freqs->branch, encoding, 0, 0);
    write_tree(dest, freqs, nitems);
    free(tree);
    free(freqs);

    int destPos = 4 + nitems * 2;
    uint32_t destBuf = 0;
    int destBitPos = 0;

    for (int srcPos = 0; srcPos < srcSize; srcPos++) {
        if (bitDepth == 8) {
            write_bits(dest, &destPos, encoding, src[srcPos], &destBuf, &destBitPos);
        }
        else {
            write_bits(dest, &destPos, encoding, src[srcPos] & 0xF, &destBuf, &destBitPos);
            write_bits(dest, &destPos, encoding, src[srcPos] >> 4, &destBuf, &destBitPos);
        }
    }

    if (destBitPos != 0) {
        dump_bits(dest, &destPos, &destBuf);
    }

    free(encoding);

    dest[0] = bitDepth | 0x20;
    dest[1] = srcSize;
    dest[2] = srcSize >> 8;
    dest[3] = srcSize >> 16;
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
        uint32_t window = src[srcPos] | (src[srcPos + 1] << 8) | (src[srcPos + 2] << 16) | (src[srcPos + 3] << 24);
        srcPos += 4;
        for (int i = 0; i < 32; i++) {
            int curBit = (window >> 31) & 1;
            unsigned char treeView = src[treePos];
            bool isLeaf = ((treeView << curBit) & 0x80) != 0;
            treePos &= ~1; // align
            treePos += ((treeView & 0x3F) + 1) * 2 + curBit;
            if (isLeaf) {
                destTmp >>= bitDepth;
                destTmp |= (src[treePos] << (32 - bitDepth));
                curValPos++;
                if (curValPos == 32 / bitDepth) {
                    dest[destPos] = destTmp;
                    dest[destPos + 1] = destTmp >> 8;
                    dest[destPos + 2] = destTmp >> 16;
                    dest[destPos + 3] = destTmp >> 24;
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
