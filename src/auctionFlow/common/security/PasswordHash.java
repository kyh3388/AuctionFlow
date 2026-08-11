package auctionFlow.common.security;

import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

import coreframe.annotations.beans.Bean;

@Bean
public class PasswordHash {
	
	private static final String ALGORITHM = "PBKDF2WithHmacSHA256"; //JAVA 표준 보안 API가 제공하는 PBKDF2 해시 알고리즘
	private static final int ITERATION_COUNT = 600_000; //해시 반복 횟수
	private static final int SALT_LENGTH = 16;
	private static final int HASH_LENGTH_BITS = 256; //최종 해시 길이
	private static final SecureRandom SECURE_RANDOM = new SecureRandom(); //보안용 무작위 난수 생성
	
	public String hash(String rawPassword) {
		
		byte[] salt = new byte[SALT_LENGTH];
		
		SECURE_RANDOM.nextBytes(salt);
		
		char[] passwordChars = rawPassword.toCharArray();
		
		try {
			
			byte[] hash = createHash(passwordChars, salt, ITERATION_COUNT);
			
			String encodeSalt = Base64.getEncoder().encodeToString(salt);
			String encodeHash = Base64.getEncoder().encodeToString(hash);
			
			return ALGORITHM + "$" + ITERATION_COUNT + "$" + encodeSalt + "$" + encodeHash;
		} catch (GeneralSecurityException e) {
			throw new IllegalStateException("비밀번호 해시 처리 중 오류가 발생했습니다.", e);
		} finally {
			Arrays.fill(passwordChars, '\0');
		}
	}
	
	//로그인 시 비밀번호 검증하기
	public boolean matches(String rawPassword, String storedPasswordHash) {
		
		try {
			String[] hashParts = storedPasswordHash.split("\\$", -1);
			
			if (hashParts.length != 4) {
				return false;
			}
			
			String algorithm = hashParts[0];
			
			int iterationCount = Integer.parseInt(hashParts[1]);
			
			byte[] salt = Base64.getDecoder().decode(hashParts[2]);
					
			byte[] storedHash = Base64.getDecoder().decode(hashParts[3]);
			
			if (!ALGORITHM.equals(algorithm)) {
				return false;
			}
			
			if (iterationCount <= 0) {
				return false;
			}
			
			char[] passwordChars = rawPassword.toCharArray();
			
			try {
				byte[] inputHash = createHash(passwordChars, salt, iterationCount);
				return MessageDigest.isEqual(storedHash, inputHash); //타이밍 공격 차단
				
			} finally {
				Arrays.fill(passwordChars, '\0');
			}
		} catch (IllegalArgumentException | GeneralSecurityException e) {
			return false;
		}
	}
	
	//해시 생성 공통 메서드
	private byte[] createHash(char[] passwordChars, byte[] salt, int iterationCount) throws GeneralSecurityException {
		
		PBEKeySpec keySpec = null;
		
		try {
			keySpec = new PBEKeySpec (passwordChars, salt, iterationCount, HASH_LENGTH_BITS);
			SecretKeyFactory secretKeyFactory = SecretKeyFactory.getInstance(ALGORITHM);
			return secretKeyFactory.generateSecret(keySpec).getEncoded();
			
		} finally {
			if (keySpec != null) {
				keySpec.clearPassword();
			}
		}
	}
}
