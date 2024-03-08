
// Parts taken from https://github.com/openjdk/jdk17u-dev/blob/a028120220f6fd28e39fe0f6190eb1f5da6a788d/make/jdk/src/classes/build/tools/generatecacerts/GenerateCacerts.java
// https://github.com/GoogleContainerTools/distroless/tree/b1e2203eceb9cc91de0500d71c648e346e1d7b89/cacerts/jksutil
import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.DigestOutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Arrays;

import javax.security.auth.x500.X500Principal;

/**
 * Generate cacerts
 */
class JavaKeyStore {

    private static final int MAGIC = 0xfeedfeed;
    private static final int VERSION = 0x02;
    private static final int TRUSTED_CERT_TAG = 0x02;
    private static final char[] PASSWORD = "changeit".toCharArray();
    private static final String SALT = "Mighty Aphrodite";

    public static void main(String[] args) throws Exception {
        try (FileOutputStream output = new FileOutputStream(args[0])) {
            store(output, Arrays.copyOfRange(args, 1, args.length));
        }
    }

    public static void store(OutputStream stream, String[] entries)
            throws IOException, NoSuchAlgorithmException, CertificateException {
        byte[] encoded; // the certificate encoding
        CertificateFactory cf = CertificateFactory.getInstance("X509");

        MessageDigest md = getPreKeyedHash(PASSWORD);
        DataOutputStream dos = new DataOutputStream(new DigestOutputStream(stream, md));

        ArrayList<X509Certificate> certs = new ArrayList<X509Certificate>();

        for (String entry : entries) {
            try (InputStream fis = Files.newInputStream(Path.of(entry))) {
                for (Certificate rcert : cf.generateCertificates(fis)) {
                    X509Certificate cert = (X509Certificate) rcert;
                    certs.add(cert);
                }
            }
        }

        dos.writeInt(MAGIC);
        dos.writeInt(VERSION);
        dos.writeInt(certs.size());

        for (X509Certificate cert : certs) {

            String alias = cert.getSubjectX500Principal().getName(X500Principal.CANONICAL);
            
            dos.writeInt(TRUSTED_CERT_TAG);

            // Write the alias
            dos.writeUTF(alias);

            // Write the (entry creation) date, which is notBefore of the cert
            dos.writeLong(cert.getNotBefore().getTime());

            // Write the trusted certificate
            encoded = cert.getEncoded();
            dos.writeUTF(cert.getType());
            dos.writeInt(encoded.length);
            dos.write(encoded);
        }

        /*
         * Write the keyed hash which is used to detect tampering with
         * the keystore (such as deleting or modifying key or
         * certificate entries).
         */
        byte[] digest = md.digest();

        dos.write(digest);
        dos.flush();
    }

    private static MessageDigest getPreKeyedHash(char[] password)
            throws NoSuchAlgorithmException, UnsupportedEncodingException {

        MessageDigest md = MessageDigest.getInstance("SHA");
        byte[] passwdBytes = convertToBytes(password);
        md.update(passwdBytes);
        Arrays.fill(passwdBytes, (byte) 0x00);
        md.update(SALT.getBytes("UTF8"));
        return md;
    }

    private static byte[] convertToBytes(char[] password) {
        int i, j;
        byte[] passwdBytes = new byte[password.length * 2];
        for (i = 0, j = 0; i < password.length; i++) {
            passwdBytes[j++] = (byte) (password[i] >> 8);
            passwdBytes[j++] = (byte) password[i];
        }
        return passwdBytes;
    }
}