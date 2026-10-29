package com.paulcarouge.komit

import org.testng.Assert.assertEquals
import org.testng.Assert.assertNotEquals
import org.testng.Assert.assertThrows
import org.testng.annotations.Test
import javax.crypto.AEADBadTagException
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/** Kept low so the suite stays fast; the count is a parameter, not part of the algorithm. */
private const val TEST_ITERATION_COUNT = 1_000

class BackupEncryptionTest {
    private val backupJson = """{"format":"komit-backup","version":2,"userName":"Zoé"}""".toByteArray()

    @Test
    fun `opens what it sealed with the same passphrase`() {
        val sealed = BackupEncryption.seal(backupJson, "correct horse".toCharArray(), TEST_ITERATION_COUNT)

        assertEquals(BackupEncryption.open(sealed, "correct horse".toCharArray(), TEST_ITERATION_COUNT), backupJson)
    }

    @Test
    fun `refuses a wrong passphrase and a tampered file`() {
        val sealed = BackupEncryption.seal(backupJson, "correct horse".toCharArray(), TEST_ITERATION_COUNT)
        val tampered = SealedBackup(sealed.salt, sealed.nonce, sealed.ciphertext.copyOf().also { it[0] = (it[0] + 1).toByte() })

        assertThrows(AEADBadTagException::class.java) {
            BackupEncryption.open(sealed, "wrong horse".toCharArray(), TEST_ITERATION_COUNT)
        }
        assertThrows(AEADBadTagException::class.java) {
            BackupEncryption.open(tampered, "correct horse".toCharArray(), TEST_ITERATION_COUNT)
        }
    }

    @Test
    fun `uses a fresh salt and nonce for every export`() {
        val first = BackupEncryption.seal(backupJson, "correct horse".toCharArray(), TEST_ITERATION_COUNT)
        val second = BackupEncryption.seal(backupJson, "correct horse".toCharArray(), TEST_ITERATION_COUNT)

        assertNotEquals(first.salt, second.salt)
        assertNotEquals(first.nonce, second.nonce)
        assertNotEquals(first.ciphertext, second.ciphertext)
    }

    @Test
    fun `derives the same key as the JDK's PBKDF2WithHmacSHA256, accents included`() {
        val passphrase = "mot de passe é".toCharArray()
        val salt = ByteArray(BACKUP_SALT_BYTE_COUNT) { it.toByte() }
        val jdkKey =
            SecretKeyFactory
                .getInstance("PBKDF2WithHmacSHA256")
                .generateSecret(PBEKeySpec(passphrase, salt, TEST_ITERATION_COUNT, 256))
                .encoded

        assertEquals(BackupEncryption.pbkdf2HmacSha256(passphrase, salt, TEST_ITERATION_COUNT), jdkKey)
    }

    @Test
    fun `refuses an iteration count that would freeze the phone`() {
        val sealed = BackupEncryption.seal(backupJson, "correct horse".toCharArray(), TEST_ITERATION_COUNT)

        assertThrows(IllegalArgumentException::class.java) {
            BackupEncryption.open(sealed, "correct horse".toCharArray(), MAXIMUM_BACKUP_KDF_ITERATION_COUNT + 1)
        }
    }
}
