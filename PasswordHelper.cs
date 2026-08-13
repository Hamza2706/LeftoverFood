using System;
using System.Security.Cryptography;
using System.Text;

namespace LeftoverFoodSystem
{
    public class PasswordHelper
    {
        private const string Prefix = "PBKDF2";
        private const int Iterations = 100000;
        private const int SaltSize = 16;
        private const int KeySize = 32;

        // Hash a plain-text password using salted PBKDF2 (format: PBKDF2$iterations$saltBase64$hashBase64)
        public static string HashPassword(string password)
        {
            byte[] salt = new byte[SaltSize];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
                rng.GetBytes(salt);

            byte[] hash = DeriveKey(password, salt, Iterations);

            return string.Join("$", Prefix, Iterations, Convert.ToBase64String(salt), Convert.ToBase64String(hash));
        }

        // Verify entered password against stored hash (handles both salted PBKDF2 and legacy unsalted SHA-256)
        public static bool VerifyPassword(string enteredPassword, string storedHash)
        {
            if (IsLegacyHash(storedHash))
                return VerifyLegacySha256(enteredPassword, storedHash);

            string[] parts = storedHash.Split('$');
            if (parts.Length != 4 || parts[0] != Prefix)
                return false;

            int iterations = int.Parse(parts[1]);
            byte[] salt = Convert.FromBase64String(parts[2]);
            byte[] expectedHash = Convert.FromBase64String(parts[3]);

            byte[] actualHash = DeriveKey(enteredPassword, salt, iterations);
            return FixedTimeEquals(actualHash, expectedHash);
        }

        // True if the stored hash is the old unsalted-SHA256 format and should be upgraded on next successful login
        public static bool IsLegacyHash(string storedHash)
        {
            return storedHash != null && !storedHash.StartsWith(Prefix + "$");
        }

        private static bool VerifyLegacySha256(string enteredPassword, string storedHash)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(enteredPassword));
                StringBuilder sb = new StringBuilder();
                foreach (byte b in bytes)
                    sb.Append(b.ToString("x2"));
                return string.Equals(sb.ToString(), storedHash, StringComparison.OrdinalIgnoreCase);
            }
        }

        private static byte[] DeriveKey(string password, byte[] salt, int iterations)
        {
            using (Rfc2898DeriveBytes pbkdf2 = new Rfc2898DeriveBytes(password, salt, iterations, HashAlgorithmName.SHA256))
                return pbkdf2.GetBytes(KeySize);
        }

        private static bool FixedTimeEquals(byte[] a, byte[] b)
        {
            if (a.Length != b.Length) return false;
            int diff = 0;
            for (int i = 0; i < a.Length; i++)
                diff |= a[i] ^ b[i];
            return diff == 0;
        }
    }
}
