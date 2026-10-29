package com.paulcarouge.komit

import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/** Bytes of random salt per export: unique keys even for two exports with the same passphrase. */
const val BACKUP_SALT_BYTE_COUNT = 16

/** The nonce size AES-GCM is designed for. */
const val BACKUP_NONCE_BYTE_COUNT = 12

/** Far above the count Dart writes (600 000); refuses a file that would keep the CPU busy for hours. */
const val MAXIMUM_BACKUP_KDF_ITERATION_COUNT = 10_000_000

private const val AES_KEY_BYTE_COUNT = 32
private const val GCM_TAG_BIT_COUNT = 128
private const val HMAC_ALGORITHM = "HmacSHA256"

/** Binds the ciphertext to the envelope format, so it cannot be replayed inside another format. */
private val ASSOCIATED_DATA = "komit-encrypted/1".toByteArray(Charsets.UTF_8)

class SealedBackup(
    val salt: ByteArray,
    val nonce: ByteArray,
    val ciphertext: ByteArray,
)

/**
 * Passphrase-protected exports: PBKDF2-HMAC-SHA256 then AES-256-GCM, see docs/adr/0005.
 * Plain JVM code, so it is unit tested; the GCM tag check makes a wrong passphrase and a
 * tampered file both throw javax.crypto.AEADBadTagException.
 */
object BackupEncryption {
    fun seal(
        plaintext: ByteArray,
        passphrase: CharArray,
        iterationCount: Int,
        random: SecureRandom = SecureRandom(),
    ): SealedBackup {
        val salt = ByteArray(BACKUP_SALT_BYTE_COUNT).also(random::nextBytes)
        val nonce = ByteArray(BACKUP_NONCE_BYTE_COUNT).also(random::nextBytes)
        val cipher = aesGcm(Cipher.ENCRYPT_MODE, passphrase, salt, nonce, iterationCount)
        return SealedBackup(salt, nonce, cipher.doFinal(plaintext))
    }

    fun open(
        sealed: SealedBackup,
        passphrase: CharArray,
        iterationCount: Int,
    ): ByteArray {
        require(sealed.salt.size == BACKUP_SALT_BYTE_COUNT && sealed.nonce.size == BACKUP_NONCE_BYTE_COUNT) {
            "Unexpected salt or nonce size"
        }
        return aesGcm(Cipher.DECRYPT_MODE, passphrase, sealed.salt, sealed.nonce, iterationCount).doFinal(sealed.ciphertext)
    }

    private fun aesGcm(
        mode: Int,
        passphrase: CharArray,
        salt: ByteArray,
        nonce: ByteArray,
        iterationCount: Int,
    ): Cipher {
        val key = pbkdf2HmacSha256(passphrase, salt, iterationCount)
        try {
            return Cipher.getInstance("AES/GCM/NoPadding").apply {
                init(mode, SecretKeySpec(key, "AES"), GCMParameterSpec(GCM_TAG_BIT_COUNT, nonce))
                updateAAD(ASSOCIATED_DATA)
            }
        } finally {
            key.fill(0)
        }
    }

    /**
     * PBKDF2 (RFC 8018) for one 32-byte block, written on top of Mac because Android 7 lacks
     * SecretKeyFactory's PBKDF2WithHmacSHA256. The passphrase is encoded in UTF-8, like the JDK's.
     */
    internal fun pbkdf2HmacSha256(
        passphrase: CharArray,
        salt: ByteArray,
        iterationCount: Int,
    ): ByteArray {
        require(passphrase.isNotEmpty()) { "Empty passphrase" }
        require(iterationCount in 1..MAXIMUM_BACKUP_KDF_ITERATION_COUNT) { "Iteration count out of range" }
        val passphraseBytes = Charsets.UTF_8.encode(java.nio.CharBuffer.wrap(passphrase)).let { buffer ->
            ByteArray(buffer.remaining()).also(buffer::get)
        }
        try {
            val mac = Mac.getInstance(HMAC_ALGORITHM).apply { init(SecretKeySpec(passphraseBytes, HMAC_ALGORITHM)) }
            val block = ByteArray(AES_KEY_BYTE_COUNT)
            mac.update(salt)
            mac.update(byteArrayOf(0, 0, 0, 1))
            mac.doFinal(block, 0)
            val derivedKey = block.copyOf()
            repeat(iterationCount - 1) {
                mac.update(block)
                mac.doFinal(block, 0)
                for (index in derivedKey.indices) {
                    derivedKey[index] = (derivedKey[index].toInt() xor block[index].toInt()).toByte()
                }
            }
            block.fill(0)
            return derivedKey
        } finally {
            passphraseBytes.fill(0)
        }
    }
}
